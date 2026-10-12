local skill = fk.CreateSkill {
  name = "bone_mirror_viewas",
}

Fk:loadTranslationTable{
  ["bone_mirror_viewas"] = "照骨镜",
}

skill:addEffect("viewas", {
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getCardIds("h"), to_select) then
      local card = Fk:getCardById(to_select)
      return (card.type == Card.TypeBasic or card:isCommonTrick()) and
        player:canUse(Fk:cloneCard(card.name), {bypass_times = true})
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Fk:getCardById(cards[1]).name)
    card.skillName = "#bone_mirror_skill"
    return card
  end,
})

return skill
