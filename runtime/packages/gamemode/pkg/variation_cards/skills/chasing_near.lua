local skill = fk.CreateSkill {
  name = "chasing_near_skill",
}

Fk:loadTranslationTable{
  ["#chasing_near-prey"] = "获得牌",
  ["#chasing_near-discard"] = "弃置牌",
}

skill:addEffect("cardskill", {
  prompt = "#chasing_near_skill",
  target_num = 1,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if player:distanceTo(to_select) == 1 then
      return "#chasing_near-prey"
    elseif player:distanceTo(to_select) > 1 then
      return "#chasing_near-discard"
    end
  end,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player and not to_select:isAllNude()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to:isAllNude() then return end
    local id = room:askToChooseCard(from, {
      target = to,
      flag = "hej",
      skill_name = skill.name,
    })
    if from:distanceTo(to) > 1 then
      room:throwCard(id, skill.name, to, from)
    elseif from:distanceTo(to) == 1 then
      room:obtainCard(from, id, false, fk.ReasonPrey, from, skill.name)
    end
  end,
})

return skill
