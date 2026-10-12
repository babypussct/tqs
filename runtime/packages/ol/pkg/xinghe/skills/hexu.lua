local hexu = fk.CreateSkill {
  name = "hexu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hexu"] = "和煦",
  [":hexu"] = "锁定技，你每有一个类别的非伤害牌，你的手牌上限便+1。",

  ["$hexu1"] = "和风拂汉柳，细雨润未央。",
  ["$hexu2"] = "妾心若春水，潺潺解君忧。",
}

hexu:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(hexu.name) then
      local types = {}
      for _, id in ipairs(player:getCardIds("he")) do
        local card = Fk:getCardById(id)
        if not card.is_damage_card then
          table.insertIfNeed(types, card.type)
        end
      end
      return #types
    end
  end,
})

return hexu
