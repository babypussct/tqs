local jinjin = fk.CreateSkill{
  name = "jinjinx",
}

Fk:loadTranslationTable{
  ["jinjinx"] = "金烬",
  [":jinjinx"] = "你可以移出本回合弃牌堆中任意张不同花色的牌并失去本技能视为使用一张普通锦囊牌，"..
    "然后你下次受到伤害的回合结束时令一名角色获得移出牌和本技能。",

  ["#jinjinx"] = "金烬：移出本回合弃牌堆中任意张不同花色的牌并失去本技能来视为使用一张普通锦囊牌",
  ["#jinjinx-choose"] = "金烬：选择一名角色令其获得移出牌和本技能",
  ["@[jinjinx]"] = "弃牌堆",

  ["$jinjinx1"] = "当燃至最后一刻，照亮前路。	",
  ["$jinjinx2"] = "余下的，便交给你了。",
}

jinjin:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jinjin.name, true) and player.room:getCurrent()
  end,
  on_refresh = function(self, event, target, player, data)
    local cards = player:getTableMark("jinjinx-turn")
    local n = #cards
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
    if #cards > n then
      player.room:setPlayerMark(player, "jinjinx-turn", cards)
    end
  end
})

jinjin:addAcquireEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "@[jinjinx]", 1)
  local cards = {}
  room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
    for _, move in ipairs(e.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
  end, nil, Player.HistoryTurn)
  if #cards > 0 then
    room:setPlayerMark(player, "jinjinx-turn", cards)
  end
end)

jinjin:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@[jinjinx]", 0)
end)

Fk:addQmlMark{
  name = "jinjinx",
  how_to_show = function(name, value, p)
    return " "
  end,
  qml = function(name, value, p)
    local discard_pile = Fk:currentRoom().discard_pile
    return {
      uri = "LunarLtk.Pages.InfoPopups",
      name = "ViewPile",
      prop = {
        ids = table.filter(p:getTableMark("jinjinx-turn"), function(id)
          return table.contains(discard_pile, id)
        end)
      },
    }
  end,
}

jinjin:addEffect("viewas", {
  pattern = ".|.|.|.|.|trick",
  prompt = "#jinjinx",
  filter_pattern = {
    min_num = 1,
    max_num = math.huge,
    subcards = {},
    pattern = ".",
  },
  expand_pile = function(self, player)
    local room = Fk:currentRoom()
    return table.filter(player:getTableMark("jinjinx-turn"), function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    local mark = player:getTableMark("jinjinx-turn")
    if table.contains(mark, to_select) and Fk:currentRoom():getCardArea(to_select) == Card.DiscardPile then
      local card = Fk:getCardById(to_select)
      if card.suit == Card.NoSuit then return false end
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id)
          return card:compareSuitWith(Fk:getCardById(id), true)
        end)
      end
    end
  end,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local names = player:getViewAsCardNames(jinjin.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data, nil, nil, jinjin.name)
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    local cards = use.card.fake_subcards
    player:addToPile("jinjinx", cards, true, jinjin.name, player)
    if not player.dead then
      player.room:handleAddLoseSkills(player, "-jinjinx")
    end
  end,
  enabled_at_play = function(self, player)
    local room = Fk:currentRoom()
    return not not table.find(player:getTableMark("jinjinx-turn"), function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
  end,
  enabled_at_response = function(self, player, response)
    local room = Fk:currentRoom()
    return not (response or not table.find(player:getTableMark("jinjinx-turn"), function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end))
  end,
})

jinjin:addEffect(fk.TurnEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and #player:getPile("jinjinx") > 0 and #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#jinjinx-choose",
      skill_name = jinjin.name,
      cancelable = false,
      no_indicate = true,
    })[1]
    local cards = player:getPile("jinjinx")
    if #cards > 0 then
      room:obtainCard(to, cards, true, fk.ReasonJustMove, player, jinjin.name)
      if to.dead then return end
    end
    room:handleAddLoseSkills(to, "jinjinx")
  end,
})

return jinjin
