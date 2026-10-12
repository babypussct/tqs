local xinyou = fk.CreateSkill{
  name = "ol__xinyou",
}

Fk:loadTranslationTable{
  ["ol__xinyou"] = "心幽",
  [":ol__xinyou"] = "出牌阶段限一次，你可以弃置任意张基本牌，然后摸一张牌，并重复此流程，直到你因此获得未弃置牌名的基本牌"..
  "（至多摸五张且本回合不计入手牌上限）。",

  ["#ol__xinyou"] = "心幽：弃置任意张基本牌，摸牌直到摸到未弃置牌名的基本牌",
  ["@@ol__xinyou-inhand-turn"] = "心幽",

  ["$ol__xinyou1"] = "独坐空庭，一腔心事唯付泪中。",
  ["$ol__xinyou2"] = "君心已远，我亦无心再争分毫。",
}

xinyou:addEffect("active", {
  anim_type = "drawcard",
  max_phase_use_time = 1,
  prompt = "#ol__xinyou",
  min_card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return player:usedSkillTimes(xinyou.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select) and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local names = table.map(effect.cards, function (id)
      return Fk:getCardById(id).trueName
    end)
    room:throwCard(effect.cards, xinyou.name, player, player)
    for _ = 1, 5 do
      if player.dead then return end
      local cards = player:drawCards(1, xinyou.name, nil, "@@ol__xinyou-inhand-turn")
      if table.find(cards, function (id)
        return Fk:getCardById(id).type == Card.TypeBasic and not table.contains(names, Fk:getCardById(id).trueName)
      end) then
        return
      end
    end
  end,
})

xinyou:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@ol__xinyou-inhand-turn") > 0
  end,
})

return xinyou
