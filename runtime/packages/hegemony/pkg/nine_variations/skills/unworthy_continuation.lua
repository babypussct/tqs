
local skill = fk.CreateSkill {
  name = "unworthy_continuation_skill",
}

skill:addEffect("cardskill", {
  prompt = "#unworthy_continuation_skill",
  can_use = Util.GlobalCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  on_effect = function(self, room, effect)
    local target = effect.to
    local cards = table.filter(room.discard_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and card.package.name == "nine_variations"
    end)
    if #cards > 0 then
      local card = room:askToChooseCard(target, {
        target = target,
        flag = { card_data = {{ skill.name, cards }} },
        skill_name = skill.name,
        prompt = "#unworthy_continuation-ask",
      })
      if target:canUseTo(Fk:getCardById(card), target) then
        room:useCard{
          from = target,
          tos = { target },
          card = Fk:getCardById(card),
        }
      end
    else
      target:drawCards(1, skill.name)
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = -1,
  use_value = 3,
  use_priority = 1.2,

  on_effect = function(self, logic, effect)
    logic:drawCards(effect.to, 1, skill.name)
  end,
})

return skill
