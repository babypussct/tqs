local kuili = fk.CreateSkill {
  name = "kuili",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuili"] = "溃离",
  [":kuili"] = "锁定技，当你受到伤害后，你恢复伤害来源的武器栏。",

  ["$kuili1"] = "此犹有转胜之机，吾等切不可自乱。",
  ["$kuili2"] = "不患败战于人，但恐军心已溃啊。",
}

kuili:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuili.name) and
      data.from and not data.from.dead and
      table.contains(data.from.sealedSlots, Player.WeaponSlot)
  end,
  on_use = function(self, event, target, player, data)
    player.room:resumePlayerArea(data.from, Player.WeaponSlot)
  end,
})

return kuili
