
local wujue = fk.CreateSkill {
  name = "wujue",
}

Fk:loadTranslationTable {
  ["wujue"] = "五绝",
  [":wujue"] = "你使用手牌结算完毕后，获得此牌名字数个“绝”标记，当“绝”的数量为5的倍数时，你移去所有“绝”，"..
  "然后亮出牌堆顶的三张牌，你可以将其中牌名字数之和为5的任意张牌交给一名角色。",

  ["@wujue"] = "绝",
  ["#wujue-give"] = "五绝：你可以将牌名字数之和为5的任意张牌交给一名角色",

  ["$wujue1"] = "",
  ["$wujue2"] = "",
}

wujue:addAuxActiveSkill("#wujue_active", {
  min_card_num = 1,
  target_num = 1,
  expand_pile = function (self, player)
    return self.cards
  end,
  card_filter = function (self, player, to_select, selected)
    if table.contains(self.cards, to_select) then
      local n = Fk:getCardById(to_select):getNameLength()
      for _, id in ipairs(selected) do
        n = n + Fk:getCardById(id):getNameLength()
      end
      return n <= 5
    end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      local n = 0
      for _, id in ipairs(selected_cards) do
        n = n + Fk:getCardById(id):getNameLength()
      end
      return n == 5
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if #selected == 1 then
      local n = 0
      for _, id in ipairs(selected_cards) do
        n = n + Fk:getCardById(id):getNameLength()
      end
      return n == 5
    end
  end,
})

wujue:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wujue.name) and
      data:isUsingHandcard(player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@wujue", data.card:getNameLength())
    if player:getMark("@wujue") % 5 == 0 then
      room:setPlayerMark(player, "@wujue", 0)
      local cards = room:getNCards(3 + player:getMark("zhengul-round"))
      room:turnOverCardsFromDrawPile(player, cards, wujue.name)
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "#wujue_active",
        prompt = "#wujue-give",
        extra_data = {
          cards = cards,
        },
      })
      if success and dat then
        room:moveCardTo(dat.cards, Card.PlayerHand, dat.targets[1], fk.ReasonGive, wujue.name, nil, true, player)
      end
      room:cleanProcessingArea(cards)
    end
  end,
})

wujue:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@wujue", 0)
end)

return wujue
