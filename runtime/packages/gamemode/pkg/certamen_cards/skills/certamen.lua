local skill = fk.CreateSkill {
  name = "certamen_skill",
}

Fk:loadTranslationTable{
  ["certamen_skill"] = "逐鹿天下",
  ["#certamen_skill"] = "亮出等于所有角色数的装备牌，每名角色将其中一张置入装备区",
  ["#certamen-ask"] = "选择一张装备置入装备区",
}

skill:addEffect("cardskill", {
  prompt = "#certamen_skill",
  can_use = Util.GlobalCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  on_action = function(self, room, use, finished)
    use.extra_data = use.extra_data or {}
    if not finished then
      local toDisplay = {}
      if use.extra_data.orig_cards then
        toDisplay = use.extra_data.orig_cards
      else
        toDisplay = room:getCardsFromPileByRule( ".|.|.|.|.|equip", #use.tos, "allPiles")
      end
      room:moveCards({
        ids = toDisplay,
        from = room:getCardOwner(toDisplay[1]),
        toArea = Card.Processing,
        moveReason = fk.ReasonPut,
      })

      use.extra_data.certamen_cards = toDisplay
      use.extra_data.certamen_result = {}
    else
      if use.extra_data and use.extra_data.certamen_cards then

        local toDiscard = table.filter(use.extra_data.certamen_cards, function(id)
          return room:getCardArea(id) == Card.Processing
        end)

        if #toDiscard > 0 then
          room:moveCards({
            ids = toDiscard,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          })
        end
      end

      use.extra_data.certamen_cards = nil
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    if not (effect.extra_data and effect.extra_data.certamen_cards) then
      return
    end

    local cards = table.filter(effect.extra_data.certamen_cards, function (id)
      return to:canMoveCardIntoEquip(id)
    end)
    if #cards == 0 then return end

    local card = room:askToChooseCard(to, {
      target = to,
      flag = { card_data = {{ skill.name, cards }} },
      skill_name = skill.name,
      prompt = "#certamen-ask",
    })

    table.insert(effect.extra_data.certamen_result, {effect.to.id, card})
    room:moveCardIntoEquip(to, card, skill.name, true, to)
    table.removeOne(effect.extra_data.certamen_cards, card)
  end,
})

return skill
