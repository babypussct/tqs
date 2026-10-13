local huchen = fk.CreateSkill {
  name = "jiange__huchen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__huchen"] = "虎臣",
  [":jiange__huchen"] = "锁定技，摸牌阶段，你额外摸X张牌（X为你杀死的敌方角色数）。",
}

huchen:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(huchen.name) then
      local room = player.room
      local n = #room.logic:getEventsOfScope(GameEvent.Death, 999, function(e)
        local death = e.data
        return death.killer == player and death.who:isEnemy(player)
      end, Player.HistoryGame)
      if n > 0 then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + event:getCostData(self).choice
  end,
})

return huchen
