local skill_name = "choose_cards_skill"

local skill = fk.CreateSkill{
  name = skill_name,
}

skill:addEffect('active', {
  card_filter = function(self, player, to_select, selected)
    if #selected >= self.num then
      return false
    end

    if not table.contains(player:getCardIds("he"), to_select) then
      local pile = self:getPile(player)
      if not table.contains(pile, to_select) then return false end
    end

    local checkpoint = true
    local card = Fk:getCardById(to_select)

    if not self.include_equip then
      checkpoint = checkpoint and (Fk:currentRoom():getCardArea(to_select) ~= Player.Equip)
    end

    if self.pattern and self.pattern ~= "" then
      checkpoint = checkpoint and (Exppattern:Parse(self.pattern):match(card))
    end
    return checkpoint
  end,
  min_card_num = function(self, player) return self.min_num end,
  max_card_num = function(self, player) return self.num end,
  card_tip = function (self, player, to_select, selected, selected_targets, card, selectable, extra_data)
    if self.cardTipName then
      local cardTip = Fk.card_tips[self.cardTipName]
      assert(cardTip)
      return cardTip.card_tip(self, player, to_select, selected, selected_targets, card, selectable, extra_data)
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local data = type(ai.data) == "table" and ai.data[4] or {}
    if type(data) ~= "table" then data = {} end
    local orig = Fk.skills[data.skillName] or skill
    local strategy = ai:findStrategyOfSkill(Fk.Ltk.AI.CardsStrategy, orig.name)
    if not strategy then
      strategy = ai:findStrategyOfSkill(Fk.Ltk.AI.CardsStrategy, skill.name)
      ---@cast strategy -nil
    end

    if not strategy then return end
    local cards, benefit = strategy:chooseCards(ai)
    if not cards then return end

    local enabled_cards, seen = {}, {}
    for _, id in ipairs(ai:getEnabledCards()) do enabled_cards[id] = true end
    for _, id in ipairs(cards) do
      if seen[id] or not enabled_cards[id] then
        ai:unSelectAll()
        return
      end
      seen[id] = true
      ai:selectCard(id, true)
    end

    -- Validate against the live dashboard before serializing the reply.  This
    -- avoids turning a cancelable empty selection or a stale card subset into
    -- an illegal request; Room will keep its normal fallback path instead.
    local feasible = ai:okButtonEnabled()
    ai:unSelectAll()
    if feasible then
      return { cards, {} }, type(benefit) == "number" and benefit or 0
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardsStrategy {
  choose_cards = function(self, ai)
    local data = ai.data[4] -- extra_data
    local available_cards = ai:getEnabledCards()

    if ai.data[3] --[[ cancelable ]] then return {}, 0 end

    return table.random(available_cards, data.min_num), 0
  end
})

return skill
