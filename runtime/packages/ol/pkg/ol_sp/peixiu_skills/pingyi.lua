local pingyi = fk.CreateSkill {
  name = "peixiu_pingyi",
}

Fk:loadTranslationTable {
  ["peixiu_pingyi"] = "冯翊",
  [":peixiu_pingyi"] = "你获得此技能后，可以回复1点体力。",

  ["#peixiu_pingyi-invoke"] = "冯翊：是否回复1点体力？",
}

pingyi:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(pingyi.name) and data.skill.name == pingyi.name and
      player:isWounded()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = pingyi.name,
      prompt = "#peixiu_pingyi-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = pingyi.name,
    }
  end
})

return pingyi
