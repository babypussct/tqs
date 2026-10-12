local shengmo = fk.CreateSkill{
  name = "shengmo",
}

Fk:loadTranslationTable{
  ["shengmo"] = "剩墨",
  [":shengmo"] = "每轮限一次，当你需使用基本牌时，你可以获得本回合弃牌堆中的一张牌（不能是以此法选择过的点数）。"..
  "若此牌点数不为最大或最小，视为你使用未以此法使用过的基本牌。",

  ["#shengmo"] = "剩墨：获得弃牌堆一张牌，若点数不为最大或最小，视为使用一张基本牌",
  ["#shengmo-obtain"] = "剩墨：获得 %arg",
  ["@@shengmo_selected"] = "点数已选",

  ["$shengmo1"] = "挥毫纵墨，诸君可见砚底之春秋。",
  ["$shengmo2"] = "余墨染青山，墨尽颜色存。",
}

---@return integer[]
local function getShengmoCards(player)
  return table.filter(player:getTableMark("shengmo_cards-turn"), function(id)
    return not table.contains(player:getTableMark("shengmo_nums"), Fk:getCardById(id).number)
  end)
end

shengmo:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player, selected_cards, selected)
    local cids = (self.interaction.spec.result or {}).cards or {}
    if #cids > 0 and #cids[1] > 0 then
      return "#shengmo-obtain:::" .. Fk:getCardById(cids[1][1]):toLogString()
    end
    return "#shengmo"
  end,
  max_round_use_time = 1,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(shengmo.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  update_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local spec = self.interaction.spec
    local dat = self.interaction.data
    spec.UIrequest = table.simpleClone(dat)
    if dat.elemType == "OptionBox" then
      if dat.option == "Cancel" then
        spec.result = nil
      end
    elseif dat.elemType == "ExpandItem" then
      if spec.result == nil then
        spec.result = { cards = { { dat.cid } } }
        spec.pendings = { dat.cid }
      else
        local cids = spec.result.cards
        local n = #cids
        cids = cids[n]
        if #cids > 0 and cids[1] == dat.cid then
          spec.result.name = nil
          spec.result.cards[n] = {}
          spec.pendings = {}
        else
          spec.result.name = dat.name
          spec.result.cards[n] = { dat.cid }
          spec.pendings = { dat.cid }
        end
      end
    end
    self.interaction.data = spec.result
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local spec = self.interaction.spec
    local refresh_data = {}
    if spec.result == nil then
      local items = {}
      local cards = player:getTableMark("shengmo_cards-turn")
      table.sort(cards, function(a, b)
        return Fk:getCardById(a).number < Fk:getCardById(b).number
      end)
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id)
        card = Fk:cloneCard(card.name, card.suit, card.number)
        local selected = table.contains(player:getTableMark("shengmo_nums"), Fk:getCardById(id).number)
        if selected then
          card:setMark("@@shengmo_selected", "")
        end
        table.insert(items, {
          prop = {
            type = "card",
            card = card,
            additional_prop = {
              selectable = not selected,
              markVisible = true
            }
          },
          cid = id,
        })
      end
      refresh_data.expandItems = items
      return refresh_data
    else
      local req = spec.UIrequest or {}
      if req.elemType == "ExpandItem" then
        local cids = spec.result.cards
        if #cids == 1 and #cids[1] > 0 then
          local cid = cids[1][1]
          local n = Fk:getCardById(cid).number
          local max_n, min_n = n, n
          for _, id in ipairs(player:getTableMark("shengmo_cards-turn")) do
            local _n = Fk:getCardById(id).number
            max_n = math.max(max_n, _n)
            min_n = math.min(min_n, _n)
          end
          if max_n > n and min_n < n and #player:getViewAsCardNames(shengmo.name, Fk:getAllCardNames("b")) > 0 then
            spec.result.cards[2] = {}
            spec.UIrequest = {
              elemType = "OptionBox",
              option = "OK"
            }
          end
        end
      end
    end
    return ViewAsSkill.refresh_interaction(self, player, selected_cards, selected_targets)
  end,
  view_as = function(self, player, cards)
    local dat = self.interaction.data
    if dat == nil or dat.name == nil then return end
    return Fk:cloneCard(dat.name, nil, nil, shengmo.name)
  end,
  feasible = function(self, player, selected, selected_cards, card)
    local cids = (self.interaction.spec.result or {}).cards or {}
    return #cids > 0 and #cids[#cids] > 0
  end,
  on_use = function(self, room, skillUseEvent, card, params)
    local player = skillUseEvent.from
    local id = skillUseEvent.interaction_data.cards[1][1]
    room:addTableMark(player, "shengmo_nums", Fk:getCardById(id).number)
    room:obtainCard(player, id, false, fk.ReasonJustMove, player, shengmo.name)
    if card then
      return {
        from = player,
        tos = skillUseEvent.tos,
        card = card,
      }
    end
  end,
  enabled_at_play = function(self, player)
    return #getShengmoCards(player) > 0 and
      player:usedSkillTimes(shengmo.name, Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #getShengmoCards(player) > 0 and
      player:usedSkillTimes(shengmo.name, Player.HistoryRound) == 0
  end,
})

shengmo:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(shengmo.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local ids = player:getTableMark("shengmo_cards-turn")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    ids = table.filter(ids, function(id)
      return table.contains(room.discard_pile, id)
    end)
    room:setPlayerMark(player, "shengmo_cards-turn", ids)
  end,
})

shengmo:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryTurn)
    ids = table.filter(ids, function(id)
      return table.contains(room.discard_pile, id)
    end)
    room:setPlayerMark(player, "shengmo_cards-turn", ids)
  end
end)

return shengmo
