
local skill = fk.CreateSkill {
  name = "#rob__jink_skill",
}

skill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
  on_effect = function(self, room, effect)
    if effect.responseToEvent then
      effect.responseToEvent.isCancellOut = true
      local player = effect.from
      local target = effect.responseToEvent.from
      if not player.dead then
        local cards = table.filter(target:getCardIds("e"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and card.package.name == "nine_variations"
        end)
        if #cards > 0 and
          room:askToSkillInvoke(player, {
            skill_name = skill.name,
            prompt = "#rare_treasure-prey::"..target.id,
          }) then
          room:doIndicate(player, { target } )
          local id = room:askToChooseCard(player, {
            target = target,
            flag = { card_data = { { "equip", cards } } },
            skill_name = skill.name,
          })
          room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, skill.name, nil, true, player)
        end
      end
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 6.2,
  use_value = 9.9,
})

return skill
