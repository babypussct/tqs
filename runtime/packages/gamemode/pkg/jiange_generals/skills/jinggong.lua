local jinggong = fk.CreateSkill {
  name = "jiange__jinggong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__jinggong"] = "惊弓",
  [":jiange__jinggong"] = "锁定技，你使用【杀】无距离限制；回合结束时，若你本回合未使用过【杀】，你失去1点体力。",
}

jinggong:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinggong.name) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.trueName == "slash"
      end, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, jinggong.name)
  end,
})

jinggong:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(jinggong.name) and card and card.trueName == "slash"
  end,
})

return jinggong
