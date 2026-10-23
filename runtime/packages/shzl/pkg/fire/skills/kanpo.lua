local kanpo = fk.CreateSkill {
  name = "kanpo",
}

Fk:loadTranslationTable{
  ["kanpo"] = "看破",
  [":kanpo"] = "你可以将一张黑色手牌当【无懈可击】使用。",

  ["#kanpo"] = "看破：你可以将一张黑色手牌当【无懈可击】使用",

  ["$kanpo1"] = "雕虫小技。",
  ["$kanpo2"] = "你的计谋被识破了。",
}

kanpo:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification|.|club,spade",
  prompt = "#kanpo",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|black|^equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = kanpo.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_nullification = function (self, player, data)
    return #player:getHandlyIds() > 0
  end,
})

-- Nullification is a contextual response, not an unconditional black-card
-- conversion.  Reuse the same public effect-benefit test as SmartAI's raw
-- Nullification path, then spend the least valuable legal black card.
kanpo:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    -- AskForUseActiveSkill carries extra_data at slot 4; AskForUseCard's
    -- response path historically carries it at slot 5.  Accept both wire
    -- shapes so the same strategy keeps the public nullification context in
    -- native QA and in the live response handler.
    local extra = type(ai.data) == "table" and (ai.data[5] or ai.data[4]) or {}
    local from = extra and extra.effectFrom and ai.room:getPlayerById(tonumber(extra.effectFrom)) or nil
    local to = extra and extra.effectTo and ai.room:getPlayerById(tonumber(extra.effectTo)) or nil
    local card = extra and extra.effectCardId and Fk:getCardById(tonumber(extra.effectCardId)) or nil
    if not to then return end

    local benefit = 0
    if from and card then
      benefit = ai:getBenefitOfEvents(function(logic)
        logic:useCard{ from = from, tos = { to }, card = card }
      end)
    end
    if benefit >= 0 and not ai:shouldProtect(to) then return end

    local best, best_value = nil, -100000
    for _, id in ipairs(ai:getEnabledCards()) do
      local converted = Fk.skills[self.skill_name]:viewAs(ai.player, { id })
      if converted and converted.trueName == "nullification" then
        local value = math.max(25, -benefit + 25) -
          (ai:getCardValue(id, "keep_value") or 0) * 20
        if value > best_value then best, best_value = { { id }, {} }, value end
      end
    end
    if best and best_value > 0 then return best, best_value end
  end,
})

return kanpo
