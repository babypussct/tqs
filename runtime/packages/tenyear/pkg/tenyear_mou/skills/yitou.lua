local yitou = fk.CreateSkill{
  name = "yitou",
}

Fk:loadTranslationTable{
  ["yitou"] = "倚投",
  [":yitou"] = "其他角色的出牌阶段开始时，若其手牌数为全场最多，你可以将所有手牌交给该角色，直到本回合结束，该角色造成伤害后，你摸一张牌。",

  ["#yitou-invoke"] = "倚投：你可以将所有手牌交给 %dest，其造成伤害后你摸一张牌",

  ["$yitou1"] = "将军威震西土，某愿效犬马之劳！",
  ["$yitou2"] = "雪中送炭？不如锦上添花！",
}

yitou:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yitou.name) and target ~= player and target.phase == Player.Play and
      not player:isKongcheng() and not target.dead and
      table.every(player.room.alive_players, function (p)
        return target:getHandcardNum() >= p:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yitou.name,
      prompt = "#yitou-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, "yitou-turn", target.id)
    room:obtainCard(target, player:getCardIds("h"), false, fk.ReasonGive, player, yitou.name)
  end,
})

yitou:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and target and table.contains(player:getTableMark("yitou-turn"), target.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yitou.name)
  end,
})

return yitou
