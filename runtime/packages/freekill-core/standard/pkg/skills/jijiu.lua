local jijiu = fk.CreateSkill {
  name = "jijiu",
}

jijiu:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach",
  prompt = "#jijiu",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("peach")
    c.skillName = jijiu.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return not response and Fk:currentRoom():getCurrent() ~= player
  end,
})

-- 急救 is only enabled for the non-response Peach rescue request.  Use it
-- for self or a confirmed/well-supported ally, and spend the lowest-value
-- legal red card.  The dying target comes from server-provided public
-- `must_targets`; no hidden card/general data is consulted.
jijiu:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    -- AskForUseActiveSkill carries extra_data at slot 4, while the
    -- AskForUseCard rescue path carries it at slot 5.  Support both native
    -- request layouts so the strategy can see the server-provided
    -- must_targets metadata in either path.
    local data = type(ai.data) == "table" and
      ((type(ai.data[5]) == "table" and ai.data[5]) or
       (type(ai.data[4]) == "table" and ai.data[4])) or {}
    local target_id = data and data.must_targets and data.must_targets[1]
    local target = target_id and ai.room:getPlayerById(tonumber(target_id)) or nil
    if not target then return end

    local relation = ai:getFactionRelation(target)
    if target ~= ai.player and not ai:shouldProtect(target) then return end

    local best, best_value = nil, -100000
    for _, id in ipairs(ai:getEnabledCards()) do
      local card = Fk.skills[self.skill_name]:viewAs(ai.player, { id })
      if card and card.trueName == "peach" then
        local value = ai:getBenefitOfEvents(function(logic)
          logic:recover{ who = target, num = 1, recoverBy = ai.player, skillName = self.skill_name }
        end)
        value = value - (ai:getCardValue(id, "keep_value") or 0) * 20
        if relation.state == "unknown" then value = value - 10 end
        if value > best_value then best, best_value = { { id }, {} }, value end
      end
    end

    if best and best_value > 0 then return best, best_value end
  end,
})

return jijiu
