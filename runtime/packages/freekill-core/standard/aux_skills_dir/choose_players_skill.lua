local choosePlayersSkill = fk.CreateSkill{
  name = "choose_players_skill",
}

choosePlayersSkill:addEffect('active', {
  card_filter = function(self, player, to_select, selected)
    return self.pattern ~= "" and Exppattern:Parse(self.pattern):match(Fk:getCardById(to_select)) and #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, cards)
    if self.pattern ~= "" and #cards == 0 then return end
    if #selected < self.num then
      return table.contains(self.targets, to_select.id)
    end
  end,
  card_tip = function (self, player, to_select, selected, selected_targets, card, selectable, extra_data)
    if self.cardTipName then
      local cardTip = Fk.card_tips[self.cardTipName]
      assert(cardTip)
      return cardTip.card_tip(self, player, to_select, selected, selected_targets, card, selectable, extra_data)
    end
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if self.targetTipName then
      local targetTip = Fk.target_tips[self.targetTipName]
      assert(targetTip)
      return targetTip.target_tip(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    end
  end,
  card_num = function(self) return self.pattern ~= "" and 1 or 0 end,
  min_target_num = function(self) return self.min_num end,
  max_target_num = function(self) return self.num end,
})

choosePlayersSkill:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local data = type(ai.data) == "table" and ai.data[4] or {}
    if type(data) ~= "table" then data = {} end
    local orig = Fk.skills[data.skillName] or choosePlayersSkill
    local strategy = ai:findStrategyOfSkill(Fk.Ltk.AI.ChoosePlayersStrategy, orig.name)
    if not strategy then
      strategy = ai:findStrategyOfSkill(Fk.Ltk.AI.ChoosePlayersStrategy, choosePlayersSkill.name)
      ---@cast strategy -nil
    end

    if not strategy then return end
    local cards, card_benefit = strategy:chooseCards(ai)

    -- A target filter can depend on the selected card.  Replay the card
    -- subset before asking the strategy for targets so getEnabledTargets()
    -- reflects the same state that the request handler will validate.
    cards = cards or {}
    local enabled_cards, card_seen = {}, {}
    for _, id in ipairs(ai:getEnabledCards()) do enabled_cards[id] = true end
    for _, id in ipairs(cards) do
      if card_seen[id] or not enabled_cards[id] then
        ai:unSelectAll()
        return
      end
      card_seen[id] = true
      ai:selectCard(id, true)
    end

    local min_cards = data.pattern and data.pattern ~= "" and 1 or 0
    if #cards < min_cards then
      ai:unSelectAll()
      return
    end

    local players, player_benefit = strategy:choosePlayers(ai)
    if players == nil then
      ai:unSelectAll()
      return
    end
    players = players or {}

    local min_num = tonumber(data.min_num) or 0
    local max_num = tonumber(data.num) or min_num
    if #players < min_num or #players > max_num then
      ai:unSelectAll()
      return
    end

    local target_seen = {}
    for _, target in ipairs(players) do
      if not target or target_seen[target.id] then
        ai:unSelectAll()
        return
      end
      target_seen[target.id] = true
      ai:selectTarget(target, true)
    end

    -- Do not hand a structurally valid but infeasible reply to Request.  A
    -- nil result lets Room apply its existing cancel/non-cancel fallback.
    local feasible = ai:okButtonEnabled()
    ai:unSelectAll()
    if not feasible then return end

    card_benefit = type(card_benefit) == "number" and card_benefit or 0
    player_benefit = type(player_benefit) == "number" and player_benefit or 0
    local card_factor = card_benefit == 0 and 1 or card_benefit
    return { cards, players }, card_factor * player_benefit
  end,
})

choosePlayersSkill:addAI(Fk.Ltk.AI.newChoosePlayersStrategy {
  choose_cards = function (self, ai)
    local data = ai.data[4] -- extra_data
    local available_cards = ai:getEnabledCards()

    if ai.data[3] --[[ cancelable ]] or data.pattern == "" then return {}, 0 end

    return table.random(available_cards, 1), 0
  end,
  choose_players = function(self, ai)
    local data = ai.data[4] -- extra_data
    local available_players = ai:getEnabledTargets()

    if ai.data[3] --[[ cancelable ]] then return {}, 0 end

    return table.random(available_players, data.min_num), 0
  end
})

return choosePlayersSkill
