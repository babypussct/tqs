local juezhi = fk.CreateSkill{
  name = "juezhi",
}

Fk:loadTranslationTable{
  ["juezhi"] = "爵制",
  [":juezhi"] = "出牌阶段，你可以弃置至少两张牌，然后从牌堆中随机获得一张点数为X的牌（X为以此法弃置的牌点数和与13的余数，若余数为0则改为13）。",

  ["#juezhi"] = "爵制：弃置至少两张牌，获得一张牌，点数为弃置牌点数之和与13的余数",

  ["$juezhi1"] = "复设五等之制，以解天下土崩之势。",
  ["$juezhi2"] = "表为建爵五等，实则藩卫帝室。",
}

juezhi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#juezhi",
  min_card_num = 2,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    local number = 0
    for _, id in ipairs(effect.cards) do
      number = number + math.max(Fk:getCardById(id).number, 0)
    end
    number = number % 13
    number = number == 0 and 13 or number
    room:throwCard(effect.cards, juezhi.name, player, player)
    if player.dead then return end
    local cards = room:getCardsFromPileByRule(".|" .. number)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, juezhi.name)
    end
  end,
})

return juezhi
