local huoji = fk.CreateSkill {
  name = "huoji",
}

Fk:loadTranslationTable{
  ["huoji"] = "火计",
  [":huoji"] = "你可以将一张红色手牌当【火攻】使用。",

  ["#huoji"] = "火计：你可以将一张红色手牌当【火攻】使用",

  ["$huoji1"] = "此火可助我军大获全胜。",
  ["$huoji2"] = "燃烧吧！",
}

huoji:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#huoji",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|red|^equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = huoji.name
    card:addSubcard(cards[1])
    return card
  end,
})

-- Fire Attack needs a second same-suit discard after the target reveals a
-- card. The reveal is private to the target until the server publishes it,
-- so this strategy must not estimate an effect by simulating the target's
-- hand. Use only the BOT's own remaining suit availability plus public
-- target facts; otherwise a server-side event simulation can make the AI's
-- choice depend on concealed card identities.
huoji:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local skill = Fk.skills[self.skill_name]
    local player = ai.player
    local best, best_value = nil, -100000
    local cards = ai:getEnabledCards()

    for _, id in ipairs(cards) do
      local source = Fk:getCardById(id)
      local card = skill:viewAs(player, { id })
      local suit = source and source:getSuitString(true)
      local follow_up = 0
      if source and suit then
        for _, other_id in ipairs(cards) do
          if other_id ~= id then
            local other = Fk:getCardById(other_id)
            if other and other:getSuitString(true) == suit then follow_up = follow_up + 1 end
          end
        end
      end

      if card and follow_up > 0 then
        ai:selectSkill(self.skill_name, true)
        ai:selectCard(id, true)
        for targets in self:searchTargetSelections(ai) do
          local legal_targets = table.filter(targets, function(target)
            return target:getHandcardNum() > 0
          end)
          if #legal_targets > 0 then
            local target = legal_targets[1]
            -- Every term here is observable without opening the target's
            -- hand: faction relation, HP and hand count are public AI input.
            -- Keep the enemy preference explicit so the privacy-safe scorer
            -- does not turn a useful active skill into friendly fire.
            local relation = type(ai.getFactionRelation) == "function" and
              ai:getFactionRelation(target) or nil
            local relationScore = relation and relation.state == "enemy" and 100 or
              relation and relation.state == "friend" and -100 or 0
            local value = relationScore +
              target:getHandcardNum() * 5 +
              (target.maxHp - target.hp) * 10 -
              20 * (ai:getCardValue(id, "keep_value") or 0) - 15
            if value > best_value then
              best, best_value = { { id }, legal_targets }, value
            end
          end
        end
        ai:unSelectAll()
      end
    end

    if best and best_value > 0 then return best, best_value end
  end,
})

return huoji
