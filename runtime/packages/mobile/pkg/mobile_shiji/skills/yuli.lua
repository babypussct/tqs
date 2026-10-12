local yuli = fk.CreateSkill {
  name = "yuli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuli"] = "驭雳",
  [":yuli"] = "锁定技，1.你造成的伤害改为雷电伤害，已是雷电伤害则伤害+1；2.你受到雷电伤害时，防止之并摸等量牌。",

  ["$yuli1"] = "驭元始之用，执生杀之机！",
  ["$yuli2"] = "号令雷霆，上照天心！",
  ["$yuli3"] = "万钧所压，再无生还！",
  ["$yuli4"] = "抗我神威者，俱为齑粉！",
  ["$yuli5"] = "玄雷淬锋，砺我神威！",
  ["$yuli6"] = "惊霆九殛，锻我神魂！",
}

yuli:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yuli.name)
  end,
  on_cost = function (self, event, target, player, data)
    local audioIndex = data.damageType ~= fk.ThunderDamage and { 1, 2 } or { 3, 4 }
    event:setCostData(self, { audio_index = table.random(audioIndex) })
    return true
  end,
  on_use = function(self, event, target, player, data)
    if data.damageType == fk.ThunderDamage then
      data:changeDamage(1)
    else
      data.damageType = fk.ThunderDamage
    end
  end,
})

yuli:addEffect(fk.DetermineDamageInflicted, {
  audio_index = { 5, 6 },
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuli.name) and
      data.damageType == fk.ThunderDamage
  end,
  on_use = function(self, event, target, player, data)
    local n = data.damage
    data:preventDamage()
    player:drawCards(n, yuli.name)
  end,
})

return yuli
