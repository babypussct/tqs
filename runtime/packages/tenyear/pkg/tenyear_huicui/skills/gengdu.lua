local gengdu = fk.CreateSkill {
  name = "gengdu",
}

Fk:loadTranslationTable{
  ["gengdu"] = "耕读",
  [":gengdu"] = "出牌阶段开始时，你可以亮出牌堆顶四张牌，并选择一种颜色的牌获得：<br>"..
  "黑色牌，然后本阶段限X次，当你使用黑色牌后，你摸两张牌，本回合不能使用或打出这些牌且不计入手牌上限；<br>"..
  "红色牌，然后本阶段限X次，你可以将一张红色牌当一张本回合未使用过的普通锦囊牌使用。<br>"..
  "（X为你本次未以此法获得的牌数）",

  ["#gengdu-ask"] = "耕读：获得一种颜色的牌，根据颜色和未获得的张数本阶段执行效果",
  ["@gengdu-phase"] = "耕读",
  ["#gengdu"] = "耕读：将一张红色牌当一张本回合未使用过的普通锦囊牌使用",
  ["@@gengdu-inhand-turn"] = "耕读",

  ["$gengdu1"] = "荷锄载露归，古卷伴青灯。",
  ["$gengdu2"] = "阡陌桑麻入目，不羡长安万户。",
}

gengdu:addEffect("viewas", {
  pattern = ".|.|.|.|.|trick",
  prompt = "#gengdu",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|red",
  },
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("t")
    local names = player:getViewAsCardNames(gengdu.name, all_names, selected_cards, player:getTableMark("gengdu-turn"))
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    return Fk:cloneCard(self.interaction.data, nil, nil, gengdu.name, cards)
  end,
  before_use = function(self, player, use)
    local mark = player:getTableMark("@gengdu-phase")
    mark[2] = mark[2] - 1
    player.room:setPlayerMark(player, "@gengdu-phase", mark[2] > 0 and mark or 0)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@gengdu-phase") ~= 0 and
      player:getMark("@gengdu-phase")[1] == "red" and player:getMark("@gengdu-phase")[2] > 0 and
      #player:getViewAsCardNames(gengdu.name, Fk:getAllCardNames("t"), nil, player:getTableMark("gengdu-turn")) > 0
  end,
  enabled_at_response = Util.FalseFunc,
  enabled_at_nullification = Util.FalseFunc,
})

gengdu:addAcquireEffect(function(self, player, is_start)
  if not is_start and player.room.current == player then
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card:isCommonTrick() then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryTurn)
    if #names > 0 then
      room:setPlayerMark(player, "gengdu-turn", names)
    end
  end
end)

gengdu:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@gengdu-phase") ~= 0 and player:getMark("@gengdu-phase")[1] == "red" and
      data.card:isCommonTrick()
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "gengdu-turn", data.card.name)
  end,
})

gengdu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gengdu.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = room:getNCards(4)
    room:turnOverCardsFromDrawPile(player, cids, gengdu.name)
    room:delay(2000)

    local cards, choices = {}, {}
    for _, id in ipairs(cids) do
      local card = Fk:getCardById(id)
      local cardType = card:getColorString()
      if not cards[cardType] then
        table.insert(choices, cardType)
      end
      cards[cardType] = cards[cardType] or {}
      table.insert(cards[cardType], id)
    end
    if #choices == 1 then
      local existingColor = choices[1]   
      if existingColor == "red" then
        table.insert(choices, "black")
      elseif existingColor == "black" then
        table.insert(choices, "red")
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = gengdu.name,
      prompt = "#gengdu-ask",
    })
    room:obtainCard(player, cards[choice], true, fk.ReasonJustMove, player, gengdu.name)
    local num=4
      if cards[choice] then
        num=4 - #cards[choice]
      end
    if not player.dead then
      room:setPlayerMark(player, "@gengdu-phase", {choice, num})
    end
    room:cleanProcessingArea(cids)
  end,
})

gengdu:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.color == Card.Black and player:getMark("@gengdu-phase") ~= 0 and
      player:getMark("@gengdu-phase")[1] == "black" and player:getMark("@gengdu-phase")[2] > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@gengdu-phase")
    mark[2] = mark[2] - 1
    room:setPlayerMark(player, "@gengdu-phase", mark[2] > 0 and mark or 0)
    player:drawCards(2, gengdu.name, nil, "@@gengdu-inhand-turn")
  end,
})

gengdu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and table.find(subcards, function(id)
      return Fk:getCardById(id):getMark("@@gengdu-inhand-turn") > 0
    end)
  end,
  prohibit_response = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and table.find(subcards, function(id)
      return Fk:getCardById(id):getMark("@@gengdu-inhand-turn") > 0
    end)
  end,
})
gengdu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@gengdu-inhand-turn") > 0
  end,
})

return gengdu
