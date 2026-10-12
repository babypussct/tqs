
local huaishu = fk.CreateSkill {
  name = "huaishu",
  dynamic_desc = function (self, player, lang)
    if player:getMark("ty__yizhu") > 0 then
      return "huaishu_inner"
    end
  end,
}

Fk:loadTranslationTable{
  ["huaishu"] = "怀姝",
  [":huaishu"] = "游戏开始时，你获得<font color='red'>♦</font>和<font color='red'>♥</font>的非装备牌各一张，称为“明珠”。"..
  "你失去“明珠”牌时，若为：<font color='red'>♦</font>，你可以弃置一名角色场上的一张牌；"..
  "<font color='red'>♥</font>，你可以令一名角色失去1点体力并摸两张牌。"..
  "结束阶段，你获得牌堆或弃牌堆中的一张“明珠”牌，然后你可以将此牌交给一名其他角色并摸一张牌。",

  [":huaishu_inner"] = "游戏开始时，你获得<font color='red'>♦</font>和<font color='red'>♥</font>的非装备牌各一张，称为“明珠”。"..
  "你失去“明珠”牌时，若为：<font color='red'>♦</font>，你可以弃置一名角色场上的一张牌；"..
  "<font color='red'>♥</font>，你可以令一名角色失去1点体力并摸两张牌。"..
  "每个结束阶段，你获得牌堆或弃牌堆中的一张“明珠”牌，然后你可以将此牌交给一名其他角色并摸一张牌。",

  ["@@huaishu-inhand"] = "明珠",
  ["#huaishu-discard"] = "怀姝：你可以弃置一名角色场上的一张牌",
  ["#huaishu-losehp"] = "怀姝：你可以令一名角色失去1点体力并摸两张牌",
  ["#huaishu-prey"] = "怀姝：获得一张“明珠”牌",
  ["#huaishu-give"] = "怀姝：你可以将“明珠”牌%arg交给一名其他角色并摸一张牌",

  ["$huaishu1"] = "",
  ["$huaishu2"] = "",
}

huaishu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huaishu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|diamond|.|.|^equip", 1)
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|heart|.|.|^equip", 1))
    if #cards > 0 then
      room:setPlayerMark(player, huaishu.name, cards)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, huaishu.name, nil, false, player)
    end
  end,
})

huaishu:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(huaishu.name) and player:getMark(huaishu.name) ~= 0 then
      for _, move in ipairs(data) do
        if move.from == player and move.to ~= player then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getTableMark(huaishu.name), info.cardId) and info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player and move.to ~= player then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getTableMark(huaishu.name), info.cardId) and
            (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
            if info.beforeCard.suit == Card.Diamond then
              local targets = table.filter(room.alive_players, function(p)
                return #p:getCardIds("ej") > 0
              end)
              local to = room:askToChoosePlayers(player, {
                targets = targets,
                min_num = 1,
                max_num = 1,
                prompt = "#huaishu-discard",
                skill_name = huaishu.name,
                cancelable = true,
              })
              if #to > 0 then
                to = to[1]
                local card = room:askToChooseCard(player, {
                  target = to,
                  flag = "ej",
                  skill_name = huaishu.name,
                })
                room:throwCard(card, huaishu.name, to, player)
                if player.dead then return end
              end
            elseif info.beforeCard.suit == Card.Heart then
              local to = room:askToChoosePlayers(player, {
                targets = room.alive_players,
                min_num = 1,
                max_num = 1,
                prompt = "#huaishu-losehp",
                skill_name = huaishu.name,
                cancelable = true,
              })
              if #to > 0 then
                to = to[1]
                room:loseHp(to, 1, huaishu.name, player)
                if not to.dead then
                  to:drawCards(2, huaishu.name)
                end
                if player.dead then return end
              end
            end
          end
        end
      end
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark(huaishu.name) ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getTableMark(huaishu.name)) do
      if room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), "@@huaishu-inhand", 1)
      end
    end
  end,
})

huaishu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return (target == player or player:getMark("ty__yizhu") > 0) and player:hasSkill(huaishu.name) and target.phase == Player.Finish and
      table.find(player:getTableMark(huaishu.name), function (id)
        return table.contains(player.room.draw_pile, id) or table.contains(player.room.discard_pile, id)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getTableMark(huaishu.name), function (id)
      return table.contains(room.draw_pile, id) or table.contains(room.discard_pile, id)
    end)
    local id = room:askToChooseCard(player, {
      target = player,
      flag = { card_data = { { huaishu.name, cards } } },
      skill_name = huaishu.name,
      prompt = "#huaishu-prey",
    })
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, huaishu.name, nil, false, player)
    if player.dead or not table.contains(player:getCardIds("h"), id) or #room:getOtherPlayers(player, false) == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#huaishu-give:::"..Fk:getCardById(id):toLogString(),
      skill_name = huaishu.name,
    })
    if #to > 0 then
      room:moveCardTo(id, Card.PlayerHand, to[1], fk.ReasonGive, huaishu.name, nil, false, player)
      if not player.dead then
        player:drawCards(1, huaishu.name)
      end
    end
  end,
})

return huaishu
