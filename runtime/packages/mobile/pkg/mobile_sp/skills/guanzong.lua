local guanzong = fk.CreateSkill{
  name = "guanzong",
}

Fk:loadTranslationTable{
  ["guanzong"] = "惯纵",
  [":guanzong"] = "出牌阶段限一次，你可以令一名其他角色<font color='red'>视为</font>对另一名其他角色造成1点伤害。",

  ["#guanzong"] = "惯纵：选择两名角色，<font color='red'>视为</font>第一名角色对第二名角色造成1点伤害",

  ["$guanzong1"] = "汝为叔父，怎可与小辈计较！",
  ["$guanzong2"] = "阿瞒生龙活虎，汝切勿胡言！",
}

guanzong:addEffect("active", {
  anim_type = "special",
  prompt = "#guanzong",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(guanzong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local from = effect.tos[1]
    local to = effect.tos[2]
    room:doIndicate(from, {to})
    room:damage{
      from = from,
      to = to,
      damage = 1,
      skillName = guanzong.name,
      isVirtualDMG = true,
    }
  end,
})

return guanzong
