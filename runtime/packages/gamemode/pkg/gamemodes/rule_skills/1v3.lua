local rule = fk.CreateSkill {
  name = "#m_1v3_rule&",
}

-- 起始手牌，神吕布8张，二号位3，三号位4， 四号位5
rule:addEffect(fk.DrawInitialCards, {
  priority = 0.001,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    if player.seat == 1 then
      data.num = 8
    else
      data.num = player.seat + 1
    end
  end,
})

-- 休整归来摸牌
rule:addEffect(fk.AfterPlayerRevived, {
  priority = 0.001,
  can_refresh = function (self, event, target, player, data)
    return player.tag["hulaoRest"] and player.hp < 6
  end,
  on_refresh = function (self, event, target, player, data)
    player:drawCards(6 - player.hp, rule.name)
  end,
})

-- 盟军死亡进入休整
rule:addEffect(fk.BeforeGameOverJudge, {
  priority = 0.001,
  can_refresh = function (self, event, target, player, data)
    return target == player and player.role ~= "lord"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local n = room:getSettings('enableDeputy') and 2 or 1
    player._splayer:setDied(false)
    if n == 1 then
      room:setPlayerRest(player, 4)
    else
      room:setPlayerRest(player, 6)
    end
    player.tag["hulaoRest"] = true
    local onlyLvbu = #room:getOtherPlayers(room:getLord()) == 0
    if onlyLvbu then
      room:gameOver({ room:getLord() })
    end
  end,
})
rule:addEffect(fk.BeforeTurnStart, {
  priority = 0.001,
  can_refresh = function (self, event, target, player, data)
    return target == player and player.tag["hulaoRest"]
  end,
  on_refresh = function (self, event, target, player, data)
    player.tag["hulaoRest"] = false
  end,
})

--暴怒！
local spec = {
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local round = room.logic:getCurrentEvent():findParent(GameEvent.Round)
    room:notifySkillInvoked(player, "m_1v3_convert", "big")
    room:setTag("m_1v3_phase2", true)
    local generals = {}
    for _, g in pairs(Fk.generals) do
      if g.hulao_status == 2 and
        g.trueName == Fk.generals[player.general].trueName and
        not table.contains(room.disabled_packs, g.package.name) and
        not table.contains(room.disabled_generals, g) then
        table.insert(generals, g)
      end
    end
    generals = table.map(generals, Util.NameMapper)
    local general = room:askToChooseGeneral(player, {
      generals = generals,
      n = 1,
    })
    room:changeHero(player, general, false, false, true, false, false)
    room:changeMaxHp(player, 6 - player.maxHp)
    room:changeHp(player, 6 - player.hp, nil, rule.name)
    player:throwAllCards("j")
    if player.chained then
      player:setChainState(false)
    end
    if not player.faceup then
      player:turnOver()
    end
    if round then
      room.current = player
      round:shutdown()
    end
  end,
}
rule:addEffect(fk.BeforeHpChanged, {
  priority = 0.001,
  can_refresh = function (self, event, target, player, data)
    return target == player and player.role == "lord" and not player.room:getTag("m_1v3_phase2")
  end,
  on_refresh = spec.on_refresh,
})
rule:addEffect(fk.AfterDrawPileShuffle, {
  priority = 0.001,
  can_refresh = function (self, event, target, player, data)
    return player.role == "lord" and not player.room:getTag("m_1v3_phase2")
  end,
  on_refresh = spec.on_refresh,
})

return rule
