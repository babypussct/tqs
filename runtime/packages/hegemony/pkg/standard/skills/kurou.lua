local kurou = fk.CreateSkill{
  name = "hs__kurou",
}

Fk:loadTranslationTable{
  ["hs__kurou"] = "苦肉",
  [":hs__kurou"] = "出牌阶段限一次，你可以弃置一张牌，然后你失去1点体力，摸三张牌，于此阶段内使用【杀】的次数上限+1。",

  ["#hs__kurou"] = "苦肉：弃置一张牌，失去1点体力，摸三张牌，本阶段使用【杀】次数+1",

  ["$hs__kurou1"] = "我这把老骨头，不算什么！",
  ["$hs__kurou2"] = "为成大业，死不足惜！",
}

kurou:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#hs__kurou",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(kurou.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, kurou.name, player, player)
    if player.dead then return end
    room:loseHp(player, 1, kurou.name)
    if player.dead then return end
    player:drawCards(3, kurou.name)
    if player.dead then return end
    room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
  end
})

-- Losing HP is a real cost. Only use 苦肉 when the player survives the cost,
-- and prefer the legal card whose discard value is lowest. The bounded bonus
-- for an existing Slash reflects the extra Slash window without changing the
-- server-side mark or use-limit rules.
kurou:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    if player.hp <= 1 then return end

    local discardable = table.filter(ai:getEnabledCards(), function(id)
      local card = Fk:getCardById(id)
      return card and not player:prohibitDiscard(card)
    end)
    if #discardable == 0 then return end

    local has_slash = table.find(player:getCardIds("h"), function(id)
      local card = Fk:getCardById(id)
      return card and card.trueName == "slash"
    end) ~= nil
    local attack_bonus = has_slash and 35 or 0
    local best_card, best_benefit = nil, -100000
    for _, id in ipairs(discardable) do
      local benefit = ai:getBenefitOfEvents(function(logic)
        logic:throwCard({ id }, self.skill_name, player, player)
        logic:loseHp(player, 1, self.skill_name)
        logic:drawCards(player, 3, self.skill_name)
      end) + attack_bonus
      if benefit > best_benefit then
        best_card, best_benefit = id, benefit
      end
    end

    if best_card and best_benefit > 0 then
      return { { best_card } }, best_benefit
    end
  end,
})

return kurou
