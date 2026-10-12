local ejue = fk.CreateSkill{
  name = "heg__ejue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__ejue"] = "扼绝",
  [":heg__ejue"] = "锁定技，当你使用【杀】对未确定势力的角色造成伤害时，此伤害+1。",

  ["$heg__ejue1"] = "莫说是你，天潢贵胄亦可杀得！",
  ["$heg__ejue2"] = "你我不到黄泉，不复相见！",
}

ejue:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ejue.name) and
      not data.chain and data.card and data.card.trueName == "slash" and
      data.to.kingdom == "unknown"
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

ejue:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return ejue

