local xinchuan = fk.CreateSkill{
  name = "xinchuan",
}

Fk:loadTranslationTable{
  ["xinchuan"] = "薪传",
  [":xinchuan"] = "当你使用的锦囊牌置入弃牌堆后，你可以令一名角色依次摸X张牌并依次弃置X张牌（X为本回合弃牌堆缺失的花色数），"..
    "若其手牌数变为体力值，其下家继续执行剩余流程。",

  ["#xinchuan-choose"] = "薪传：选择一名角色，令其摸弃",
  ["#xinchuan-discard"] = "薪传：请弃置1张牌，当前已弃置了%arg张牌，需要弃置至%arg2张牌（本回合弃牌堆中花色：%arg3）",

  ["$xinchuan1"] = "火光虽微，但火种不灭。",
  ["$xinchuan2"] = "此身虽朽，未竟之谋当付来人。",
}

xinchuan:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player.room:getCurrent() == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getBanner("xinchuan-turn") or {}
    local n = #cards
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
    if #cards > n then
      player.room:setBanner("xinchuan-turn", cards)
    end
  end
})

xinchuan:addAcquireEffect(function(self, player)
  local room = player.room
  local cards = {}
  room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
    for _, move in ipairs(e.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
  end, nil, Player.HistoryTurn)
  if #cards > 0 then
    room:setBanner("xinchuan-turn", cards)
  end
end)

---@return integer
local getXinchuanNum = function()
  local room = Fk:currentRoom()
  local suits = { 1, 2, 3, 4 }
  for _, id in ipairs(room:getBanner("xinchuan-turn")) do
    if room:getCardArea(id) == Card.DiscardPile and table.removeOne(suits, Fk:getCardById(id).suit) and #suits == 0 then
      return 0
    end
  end
  return #suits
end

local U = require "packages.utility.utility"

xinchuan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xinchuan.name) and player.room:getCurrent() then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing then
              local move_event = player.room.logic:getCurrentEvent()
              local parent_event = move_event.parent
              if parent_event and parent_event.event == GameEvent.UseCard then
                local parent_data = parent_event.data
                if parent_data.from == player and parent_data.card.type == Card.TypeTrick then
                  return getXinchuanNum() > 0
                end
              end
              return false
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = xinchuan.name,
      prompt = "#xinchuan-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    for i = 1, 4, 1 do
      if i > getXinchuanNum() then break end
      to:drawCards(1, xinchuan.name)
      if to.dead then return end
      if to:getHandcardNum() == to.hp then
        if to:getNextAlive() == to then return end
        to = to:getNextAlive() ---@class ServerPlayer
      end
    end

    for i = 1, 4, 1 do
      local suits = {}
      for _, id in ipairs(room:getBanner("xinchuan-turn")) do
        if room:getCardArea(id) == Card.DiscardPile then
          local suit = Fk:getCardById(id).suit
          if suit ~= Card.NoSuit and table.insertIfNeed(suits, U.ConvertSuit(suit, "int", "icon")) and i + #suits > 4 then
            return
          end
        end
      end
      if #room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xinchuan.name,
        prompt = "#xinchuan-discard:::" .. i .. ":" .. (4 - #suits) .. ":" .. table.concat(suits, " "),
        cancelable = false,
      }) == 0 or to.dead then return end
      if to:getHandcardNum() == to.hp then
        if to:getNextAlive() == to then return end
        to = to:getNextAlive() ---@class ServerPlayer
      end
    end

  end,
})

return xinchuan
