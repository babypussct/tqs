
local chijie = fk.CreateSkill {
  name = "ol__chijie",
}

Fk:loadTranslationTable{
  ["ol__chijie"] = "持节",
  [":ol__chijie"] = "每回合限一次，当你受到其他角色使用伤害牌造成的伤害后，你可以令此伤害牌无效；"..
  "当其他角色对你使用牌后，若此牌未造成伤害，你可以获得之。",

  ["#ol__chijie-invoke"] = "持节：你可以令 %arg 在接下来的结算中无效",
  ["#ol__chijie-prey"] = "持节：你可以获得此 %arg",

  ["$ol__chijie1"] = "持节阻战，奉帝赐诏。",
  ["$ol__chijie2"] = "此战不在急，请仲达明了。",
}

chijie:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chijie.name) and
      data.from and data.from ~= player and data.card and data.card.is_damage_card and
      player:usedSkillTimes(chijie.name, Player.HistoryTurn) == 0 then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return use_event and #use_event.data.tos > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#ol__chijie-invoke:::" .. data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      use_event.data.nullifiedTargets = table.simpleClone(room:getOtherPlayers(player, false))
    end
  end,
})

chijie:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(chijie.name) and
      not data.damageDealt and table.contains(data.tos, player) and
      table.contains({ Card.Processing, Card.PlayerEquip, Card.PlayerJudge }, player.room:getCardArea(data.card)) and
      player:usedSkillTimes(chijie.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#ol__chijie-prey:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonPrey, player, chijie.name)
  end,
})

return chijie
