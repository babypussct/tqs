local jiren = fk.CreateSkill {
  name = "jiren",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jiren"] = "激刃",
  [":jiren"] = "限定技，出牌阶段，你可以令所有角色本局游戏使用非武器牌不能指定自己为目标。",

  ["#jiren-active"] = "激刃：你可令所有角色本局游戏使用非武器牌不能指定自己为目标",
  ["@[:]jiren_debuff"] = "激刃",
  ["jiren_debuff_desc"] = "",
  [":jiren_debuff_desc"] = "所有角色使用非武器牌不能指定自己为目标",

  ["$jiren1"] = "久闻文远盛名，今日且试君斤两。",
  ["$jiren2"] = "文远来的正好，顺正欲讨教一二。",
}

jiren:addEffect("active", {
  prompt = "#jiren-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jiren.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    if not room:getBanner("@[:]jiren_debuff") then
      room:setBanner("@[:]jiren_debuff", "jiren_debuff_desc")
    end
  end,
})

jiren:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return
      from and
      from == to and
      card and
      card.sub_type ~= Card.SubtypeWeapon and
      Fk:currentRoom():getBanner("@[:]jiren_debuff") == "jiren_debuff_desc"
  end,
})

return jiren
