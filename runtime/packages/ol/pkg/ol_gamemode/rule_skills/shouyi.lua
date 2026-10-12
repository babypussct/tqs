local shouyi = fk.CreateSkill{
  name = "shouyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shouyi"] = "兽裔",
  [":shouyi"] = "锁定技，你使用牌无距离限制。",
}

shouyi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(shouyi.name) and card
  end,
})

return shouyi
