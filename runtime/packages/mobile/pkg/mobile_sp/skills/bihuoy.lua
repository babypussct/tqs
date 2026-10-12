local bihuoy = fk.CreateSkill {
  name = "bihuoy",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["bihuoy"] = "避祸",
  [":bihuoy"] = "限定技，一名角色脱离濒死状态时，你可以令其摸三张牌，然后除其以外的角色本轮计算与其的距离时+X（X为场上角色数）。",

  ["#bihuoy-invoke"] = "避祸：你可以令 %dest 摸三张牌且本轮所有角色至其距离增加",
  ["@bihuoy-round"] = "避祸",

  ["$bihuoy1"] = "公以败兵之身投之，功轻且恐难保身也。",
  ["$bihuoy2"] = "公不若附之他人与相拒，然后委质，功必多。",
}

bihuoy:addEffect(fk.AfterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target:isAlive() and
      player:hasSkill(bihuoy.name) and
      player:usedSkillTimes(bihuoy.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = bihuoy.name, prompt = "#bihuoy-invoke::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { target })
    target:drawCards(3, bihuoy.name)
    room:setPlayerMark(target, "@bihuoy-round", #room.players)
  end,
})

bihuoy:addEffect("distance", {
  correct_func = function(self, from, to)
    return to:getMark("@bihuoy-round")
  end,
})

return bihuoy
