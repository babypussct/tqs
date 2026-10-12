local niqu = fk.CreateSkill {
  name = "changshi__niqu",
}

Fk:loadTranslationTable{
  ["changshi__niqu"] = "逆取",
  [":changshi__niqu"] = "出牌阶段限一次，你可以对一名角色造成1点火焰伤害。",

  ["#changshi__niqu"] = "逆取：对一名角色造成1点火焰伤害",

  ["$changshi__niqu1"] = "离心离德，为吾等所不容！",
}

niqu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#changshi__niqu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(niqu.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    room:damage{
      from = effect.from,
      to = effect.tos[1],
      damage = 1,
      damageType = fk.FireDamage,
      skillName = niqu.name,
    }
  end,
})

return niqu
