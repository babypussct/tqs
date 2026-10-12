local kongwu = fk.CreateSkill {
  name = "kongwu",
  max_phase_use_time = 1,
}

Fk:loadTranslationTable {
  ["kongwu"] = "孔武",
  [":kongwu"] = "出牌阶段限一次，你可以选择一名其他角色并展示其一张手牌，令其弃置手牌中所有与此牌花色相同的牌，然后你视为对其使用X张【杀】"..
  "（X为该角色手牌和装备区里与此牌类别相同的牌数）。若其没有因此受到伤害，你将手牌摸至体力上限。" ..
  "此阶段结束时，若其手牌数和体力值均不大于你，其下回合装备区内的牌失效且摸牌阶段摸牌数-1。",

  ["#kongwu"] = "孔武：展示一名其他角色一张手牌，其弃置所有花色相同的手牌且你视为对其使用【杀】",
  ["@@kongwu-turn"] = "孔武",

  ["$kongwu1"] = "臂有千斤力，何惧万人敌！",
  ["$kongwu2"] = "莫说兵器，取汝首级也易如反掌。",
}

kongwu:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#kongwu",
  card_filter = Util.FalseFunc,
  max_phase_use_time = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kongwu.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = { room:askToChooseCard(player, {
      skill_name = kongwu.name,
      target = target,
      flag = "h",
    }) }
    room:addTableMarkIfNeed(player, "kongwu-phase", target.id)
    target:showCards(cards, player)
    if player.dead or target.dead then return end
    local realCard = Fk:getCardById(cards[1])
    local to_throws = table.filter(target:getCardIds("h"), function(id)
      return Fk:getCardById(id).suit == realCard.suit
    end)
    if #to_throws > 0 then
      room:throwCard(to_throws, kongwu.name, target, player)
    end

    if player.dead or target.dead then return end

    local n = table.reduce(target:getCardIds("he"), 0, function(acc, id)
      local card = Fk:getCardById(id)
      if card.type == realCard.type then
        return acc + 1
      end
      return acc
    end)
    local no_hitted = true
    for _ = 1, n, 1 do
      if not (player.dead or target.dead) then
        local use = room:useVirtualCard("slash", nil, player, target, kongwu.name, true)
        if not use then break end
        if no_hitted and use.damageDealt and use.damageDealt[target] then
          no_hitted = false
        end
      else
        break
      end
    end

    if not player.dead and no_hitted then
      local draws = player.maxHp - player:getHandcardNum()
      if draws > 0 then
        player:drawCards(draws, kongwu.name)
      end
    end
  end,
})

kongwu:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("kongwu-phase") ~= 0 and
        table.find(player:getTableMark("kongwu-phase"), function(id)
          local to = player.room:getPlayerById(id)
          return not to.dead and to:getHandcardNum() <= player:getHandcardNum() and to.hp <= player.hp
        end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = table.filter(player:getTableMark("kongwu-phase"), function(id)
      local to = room:getPlayerById(id)
      return not to.dead and to:getHandcardNum() <= player:getHandcardNum() and to.hp <= player.hp
    end)
    tos = table.map(tos, Util.Id2PlayerMapper)
    room:sortByAction(tos)
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      room:addPlayerMark(p, kongwu.name, 1)
    end
  end,
})
kongwu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(kongwu.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@kongwu-turn", player:getMark("kongwu"))
    room:setPlayerMark(player, "kongwu", 0)
  end,
})
kongwu:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@kongwu-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n - player:getMark("@@kongwu-turn")
  end,
})

kongwu:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@kongwu-turn") > 0 and skill:isEquipmentSkill(from)
  end,
})

return kongwu
