local fire_attack = fk.CreateSkill{
  name = "zhitian__fire_attack_skill",
}

Fk:loadTranslationTable{
  ["zhitian__fire_attack_skill"] = "火攻",
}

fire_attack:addEffect("cardskill", {
  prompt = "#fire_attack_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, _, to_select, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to:isKongcheng() then return end

    local params = { ---@type AskToCardsParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fire_attack.name,
      cancelable = false,
      pattern = ".|.|.|hand",
      prompt = "#fire_attack-show:" .. from.id
    }
    local showCard = room:askToCards(to, params)[1]
    local suit = Fk:getCardById(showCard):getSuitString()

    to:showCards(showCard)

    local c
    local handcards = table.filter(from:getCardIds("h"), function (id)
      c = Fk:getCardById(id)
      return c:getSuitString() == suit and not from:prohibitDiscard(c)
    end)
    local pile = {}
    local x = from:getMark("@[zhitian]")
    for _, id in ipairs(room.draw_pile) do
      if #pile == x then break end
      table.insert(pile, id)
      if Fk:getCardById(id):getSuitString() == suit then
        table.insert(handcards, id)
      end
    end

    params = { ---@type AskToCardsParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = "zhitian",
      cancelable = true,
      pattern = tostring(Exppattern{ id = handcards}),
      expand_pile = pile,
      prompt = "#fire_attack-discard:" .. to.id .. "::" .. suit
    }

    --火攻特化的特殊效果
    if effect.extra_data and effect.extra_data.extra_effect then
      local extra_effects = effect.extra_data.extra_effect or {}
      for k, func in pairs(extra_effects) do
        if type(func) == "function" then
          params = func(room, effect, Fk:getCardById(showCard), params)
        end
      end
      if not params.skill_name then
        params.skill_name = "zhitian"
      end
    end

    local cards = room:askToCards(from, params)
    if #cards > 0 then
      if table.contains(from:getCardIds("h"), cards[1]) then
        room:throwCard(cards, fire_attack.name, from, from)
      else
        room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "zhitian", nil, nil, from)
      end

      if not to.dead then
        room:damage({
          from = from,
          to = to,
          card = effect.card,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = fire_attack.name,
        })
      end
    end
  end,
})

return fire_attack
