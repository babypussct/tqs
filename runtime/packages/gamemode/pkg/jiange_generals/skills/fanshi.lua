local fanshi = fk.CreateSkill {
  name = "jiange__fanshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__fanshi"] = "反噬",
  [":jiange__fanshi"] = "锁定技，结束阶段，你失去1点体力。",
}

fanshi:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fanshi.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, fanshi.name)
  end,
})

return fanshi
