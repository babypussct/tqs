
local zhiheng = fk.CreateSkill{
  name = "ex__zhiheng",
}

Fk:loadTranslationTable{
  ["ex__zhiheng"] = "制衡",
  [":ex__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌并摸等量的牌。若你以此法弃置了所有的手牌，你多摸一张牌。",

  ["#ex__zhiheng"] = "制衡：弃置任意张牌并摸等量的牌，若弃置了所有的手牌，你多摸一张牌",

  ["$ex__zhiheng1"] = "不急不躁，稳谋应对。",
  ["$ex__zhiheng2"] = "制衡互牵，大局可安。",
}

zhiheng:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ex__zhiheng",
  min_card_num = 1,
  target_num = 0,
  max_phase_use_time = 1,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local hand = player:getCardIds("h")
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    room:throwCard(effect.cards, zhiheng.name, player, player)
    if not player.dead then
      room:drawCards(player, #effect.cards + (more and 1 or 0), zhiheng.name)
    end
  end
})

zhiheng:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local cards = ai:getEnabledCards()

    local ret, benefit = nil, -100000
    if not player:isKongcheng() and
      table.every(player:getCardIds("h"), function (id)
        return table.contains(cards, id)
      end) then
      ret = player:getCardIds("h")
      table.insertTable(ret, table.filter(cards, function(id)
        return not table.contains(ret, id) and ai:getCardValue(id) <= 45
      end))
      benefit = ai:getBenefitOfEvents(function(logic)
        logic:throwCard(ret, self.skill_name, player, player)
        logic:drawCards(player, #ret + 1, self.skill_name)
      end)
    end

    cards = table.filter(cards, function(id)
      return ai:getCardValue(id) <= 45
    end)

    if #cards > 0 then
      local effect_benefit = ai:getBenefitOfEvents(function(logic)
        logic:throwCard(cards, self.skill_name, player, player)
        logic:drawCards(player, #cards, self.skill_name)
      end)
      if effect_benefit > benefit then
        ret, benefit = cards, effect_benefit
      end
    end
    if ret then
      return { ret }, benefit
    end
  end,
})

return zhiheng
