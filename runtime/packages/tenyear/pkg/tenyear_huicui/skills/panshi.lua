local panshi = fk.CreateSkill {
  name = "panshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["panshi"] = "叛弑",
  [":panshi"] = "锁定技，准备阶段，你交给有〖慈孝〗的角色一张手牌。"..
    "你于出牌阶段使用的【杀】对其造成的伤害+1且使用【杀】对其造成伤害后结束出牌阶段。",

  ["#panshi-give-to"] = "叛弑：你需将一张手牌交给%src",
  ["#panshi-give"] = "叛弑：你需将一张手牌交给拥有〖慈孝〗的角色",
}

panshi:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and
      player:hasSkill(panshi.name) and not player:isKongcheng() and
      table.find(player.room.alive_players, function(p)
        return p ~= player and p:hasSkill("cixiao", true)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local fathers = table.filter(player.room.alive_players, function(p)
      return p ~= player and p:hasSkill("cixiao", true)
    end)
    event:setCostData(self, { tos = fathers })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.dead or player:isKongcheng() then return end
    local fathers = table.filter(event:getCostData(self).tos, function(p)
      return not p.dead
    end)
    if #fathers == 1 then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        prompt = "#panshi-give-to:"..fathers[1].id,
        skill_name = panshi.name,
        cancelable = false,
      })
      room:obtainCard(fathers[1], card, false, fk.ReasonGive, player, panshi.name)
    elseif #fathers > 1 then
      local to, card = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = fathers,
        pattern = ".|.|.|hand",
        skill_name = panshi.name,
        prompt = "#panshi-give",
        cancelable = false,
      })
      room:obtainCard(to[1], card, false, fk.ReasonGive, player, panshi.name)
    end
  end,
})

panshi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(panshi.name) and player.phase == Player.Play and
      data.card and data.card.trueName =="slash" and data.to:hasSkill("cixiao", true) and
      player.room.logic:damageByCardEffect()
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

panshi:addEffect(fk.Damage, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(panshi.name) and player.phase == Player.Play and
      data.card and data.card.trueName =="slash" and data.to:hasSkill("cixiao", true) and
      player.room.logic:damageByCardEffect()
  end,
  on_use = function(self, event, target, player, data)
    player:endPlayPhase()
  end,
})

panshi:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@@panshi_son", 1)
end)

panshi:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@@panshi_son", 0)
end)

return panshi
