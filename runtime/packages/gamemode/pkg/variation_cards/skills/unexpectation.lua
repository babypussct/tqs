local skill = fk.CreateSkill {
  name = "unexpectation_skill",
}

skill:addEffect("cardskill", {
  prompt = "#unexpectation_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target:isKongcheng() then return end
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = skill.name,
    })
    target:showCards(card)
    card = Fk:getCardById(card)
    if target.dead then return end
    if card:compareSuitWith(effect.card, true) then
      room:damage{
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return skill
