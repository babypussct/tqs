local xinghuo = fk.CreateSkill{
  name = "ty_heg__xinghuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_heg__xinghuo"] = "兴火",
  [":ty_heg__xinghuo"] = "锁定技，当你造成火属性伤害时，你令此伤害+1。",

  ["$ty_heg__xinghuo1"] = "莲花佑兴，业火可兴。",
  ["$ty_heg__xinghuo2"] = "昔日莲花开，今日红火燃。",
}

xinghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xinghuo.name) and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return xinghuo
