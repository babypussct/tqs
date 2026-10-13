local liewei = fk.CreateSkill {
  name = "v11__liewei",
}

Fk:loadTranslationTable{
  ["v11__liewei"] = "裂围",
  [":v11__liewei"] = "当你杀死对手的角色后，你可以摸三张牌。",

  ["$v11__liewei1"] = "敌阵已乱，速速突围！",
  ["$v11__liewei2"] = "杀你，如同捻死一只蚂蚁！",
}

liewei:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(liewei.name) and data.killer == player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, liewei.name)
  end,
})

return liewei
