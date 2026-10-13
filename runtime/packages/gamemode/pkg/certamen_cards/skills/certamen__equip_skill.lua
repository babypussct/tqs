local skill = fk.CreateSkill{
  name = "certamen__equip_skill",
}

Fk:loadTranslationTable{
  ["#certamen__equip_skill"] = "令一名其他角色装备【%arg】",
}

skill:addEffect("cardskill", {
  prompt = function(self, player, selected_cards, _)
    if not selected_cards or #selected_cards == 0 then return " " end
    return "#certamen__equip_skill:::" .. Fk:getCardById(selected_cards[1]).name
  end,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player and #to_select:getAvailableEquipSlots(card.sub_type) > 0
  end,
  target_num = 1,
  target_filter = Util.CardTargetFilter,
})

return skill
