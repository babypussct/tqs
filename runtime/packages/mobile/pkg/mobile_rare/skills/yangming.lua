local yangming = fk.CreateSkill {
  name = "friend__yangming",
}

Fk:loadTranslationTable{
  ["friend__yangming"] = "养名",
  [":friend__yangming"] = "出牌阶段结束时，若你本阶段失去过至少三张手牌，你可以亮出牌堆顶的X张牌（X为本回合进入过弃牌堆的牌的花色数），"..
  "使用其中任意张花色各不相同的牌（无次数限制）。",

  ["#friend__yangming-use"] = "养名：你可以使用其中任意张花色各不相同的牌",

  ["$friend__yangming1"] = "但为国养士，为主选才耳。",
  ["$friend__yangming2"] = "贤人何其之多，但无识才之人也。",
}

---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

yangming:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yangming.name) and player.phase == Player.Play then
      local room = player.room
      local n = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if n < 3 then return end
      if player:hasSkill("pangtong__gongli") and GongliFriend(room, player, "friend__zhugeliang") then
        return true
      else
        return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.toArea == Card.DiscardPile then
              for _, info in ipairs(move.moveInfo) do
                if Fk:getCardById(info.cardId).suit ~= Card.NoSuit then
                  return true
                end
              end
            end
          end
        end, Player.HistoryTurn) > 0
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local suits = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(suits, Fk:getCardById(info.cardId).suit)
          end
        end
      end
    end, Player.HistoryTurn)
    table.removeOne(suits, Card.NoSuit)
    local n = #suits
    if player:hasSkill("pangtong__gongli") and GongliFriend(room, player, "friend__zhugeliang") then
      n = n + 1
    end
    local cards = room:getNCards(n)
    room:turnOverCardsFromDrawPile(player, cards, yangming.name)
    if player.dead then
      room:cleanProcessingArea(cards)
      return
    end
    suits = {}
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).suit ~= Card.NoSuit
    end)
    while #cards > 0 and not player.dead do
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.Processing and not table.contains(suits, Fk:getCardById(id).suit)
      end)
      if #cards == 0 then break end
      local use = room:askToUseRealCard(player, {
        skill_name = yangming.name,
        prompt = "#friend__yangming-use",
        pattern = tostring(Exppattern{ id = cards }),
        cancelable = true,
        extra_data = {
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        table.insert(suits, use.card.suit)
        room:useCard(use)
      else
        break
      end
    end
    room:cleanProcessingArea(cards)
    if player:hasSkill("pangtong__gongli") and GongliFriend(room, player, "friend__xushu") then
      player:broadcastSkillInvoke("pangtong__gongli")
      room:notifySkillInvoked(player, "pangtong__gongli", "drawcard")
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile and not table.contains(suits, Fk:getCardById(id).suit) and
          Fk:getCardById(id).suit ~= Card.NoSuit
      end)
      if #cards > 0 then
        if #cards > 1 then
          cards = room:askToChooseCard(player, {
            target = player,
            flag = { card_data = {{ yangming.name, cards }} },
            skill_name = yangming.name,
            prompt = "#pangtong__gongli-prey",
          })
        end
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, yangming.name, nil, true, player)
      end
    end
  end,
})

return yangming
