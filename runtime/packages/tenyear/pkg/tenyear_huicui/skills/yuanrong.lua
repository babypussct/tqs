local yuanrong = fk.CreateSkill {
  name = "yuanrong",
}

Fk:loadTranslationTable{
  ["yuanrong"] = "圆融",
  [":yuanrong"] = "回合结束时，令“圆融”牌为本回合到目前为止进入弃牌堆的牌，你先选择是否将其中一张黑色牌当任意普通锦囊牌使用，再选择是否将其中一张红色牌当任意基本牌使用。",

  ["#yuanrong-black"] = "圆融：你可以将其中一张牌当任意普通锦囊牌使用",
  ["#yuanrong-red"] = "圆融：你可以将其中一张牌当任意基本牌使用",

  ["$yuanrong1"] = "话说三分不定，活儿做半成夸功。",
  ["$yuanrong2"] = "浇脂于身，体滑方游于殿陛。",
}

yuanrong:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yuanrong.name) then
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if #cards > 0 then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)

    local black_cards = table.filter(cards, function(id) return Fk:getCardById(id).color == Card.Black end)
    local red_cards = table.filter(cards, function(id) return Fk:getCardById(id).color == Card.Red end)
    if #black_cards > 0 and
      table.find(black_cards, function (id)
        return #player:getViewAsCardNames(yuanrong.name, Fk:getAllCardNames("b"), {id}) > 0
      end) then
      room:askToUseVirtualCard(player, {
        name = Fk:getAllCardNames("t"),
        skill_name = yuanrong.name,
        prompt = "#yuanrong-black",
        cancelable = true,
        -- extra_data = {
        --   bypass_times = true,
        --   extraUse = true,
        -- },
        card_filter = {
          n = 1,
          cards = black_cards,
        },
      })

      if player.dead then return end
    end

    if #red_cards > 0 and
      table.find(red_cards, function (id)
        return #player:getViewAsCardNames(yuanrong.name, Fk:getAllCardNames("b"), {id}) > 0
      end) then
      room:askToUseVirtualCard(player, {
        name = Fk:getAllCardNames("b"),
        skill_name = yuanrong.name,
        prompt = "#yuanrong-red",
        cancelable = true,
        -- extra_data = {
        --   bypass_times = true,
        --   extraUse = true,
        -- },
        card_filter = {
          n = 1,
          cards = red_cards,
        },
      })
    end
  end,
})

return yuanrong
