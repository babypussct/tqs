local jiguan = fk.CreateSkill {
  name = "jiange__jiguan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__jiguan"] = "机关",
  [":jiange__jiguan"] = "锁定技，你不能成为【乐不思蜀】的目标。",
}

jiguan:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(jiguan.name) and card and card.name == "indulgence"
  end,
})

return jiguan
