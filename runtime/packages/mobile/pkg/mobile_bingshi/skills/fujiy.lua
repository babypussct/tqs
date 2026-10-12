local fujiy = fk.CreateSkill {
  name = "fujiy",
}

Fk:loadTranslationTable{
  ["fujiy"] = "符济",
  [":fujiy"] = "出牌阶段限一次，你可以展示并交给任意名其他角色各一张牌，这些牌称为“符济”牌。<br>"..
  "一名角色使用“符济”牌时获得一张与“符济”牌相同花色的牌。若“符济”牌为【杀】，此【杀】伤害基数值+1；若为【闪】，则结算后使用者摸一张牌。<br>"..
  "若你发动此技能交出牌后手牌数为全场最少，你摸一张牌，且你使用的第一张【杀】和【闪】带有以上“符济”牌效果直到你下回合开始。",

  ["#fujiy"] = "符济：展示至多%arg张牌交给等量其他角色，这些牌被使用时具有额外效果",
  ["#fujiy-give"] = "符济：将这些牌交给其他角色",
  ["@@fujiy-inhand"] = "符济",

  ["$fujiy1"] = "此符上格神明，下通幽府，有诸般之神效。",
  ["$fujiy2"] = "吾所书之符尚可鞭笞百鬼，更况些许小疾。",
  ["$fujiy3"] = "得天意者寿，失天意者亡。",
  ["$fujiy4"] = "天者养人命，地者养人形。",
  ["$fujiy5"] = "天地有常法，不失铢分也。",
}

fujiy:addEffect("active", {
  anim_type = "support",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#fujiy:::"..(#Fk:currentRoom().alive_players - 1)
  end,
  min_card_num = 1,
  max_card_num = function (self, player)
    return #Fk:currentRoom().alive_players - 1
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fujiy.name, Player.HistoryPhase) == 0 and
      #Fk:currentRoom().alive_players > 1
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < #Fk:currentRoom().alive_players - 1
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = table.simpleClone(effect.cards)
    player:showCards(effect.cards)
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("he"), id)
    end)
    if player.dead or #cards == 0 or #room:getOtherPlayers(player, false) == 0 then return end
    room:delay(2000)   --delay到展示的牌从处理区消失，避免yiji过程中贴给牌的mark出现在处理区的牌上！
    local n = math.min(#cards, #room:getOtherPlayers(player, false))
    local result = room:askToYiji(player, {
      cards = cards,
      targets = room:getOtherPlayers(player, false),
      skill_name = fujiy.name,
      min_num = n,
      max_num = n,
      prompt = "#fujiy-give",
      single_max = 1,
      cancelable = false,
      skip = true,
    })
    local moves = {}
    for id, ids in pairs(result) do
      if #ids > 0 then
        table.insert(moves, {
          ids = ids,
          from = player,
          to = room:getPlayerById(id),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          skillName = fujiy.name,
          proposer = player,
          moveVisible = true,
          moveMark = "@@fujiy-inhand",
        })
      end
    end
    room:moveCards(table.unpack(moves))
    if not player.dead and table.every(room.alive_players, function (p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end) then
      room:setPlayerMark(player, fujiy.name, {"slash", "jink"})
      player:drawCards(1, fujiy.name)
    end
  end
})

fujiy:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      (
        table.find(Card:getIdList(data.card), function(id)
          return Fk:getCardById(id, true):getMark("@@fujiy-inhand") > 0
        end) or
        table.contains(player:getTableMark(fujiy.name), data.card.trueName)
      )
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.fujiy = {}
    if player.room:removeTableMark(player, fujiy.name, data.card.trueName) then
      table.insert(data.extra_data.fujiy, data.card)
    end
    for _, id in ipairs(Card:getIdList(data.card)) do
      local card = Fk:getCardById(id, true)
      if card:getMark("@@fujiy-inhand") > 0 then
        table.insert(data.extra_data.fujiy, card)
      end
    end
  end,
})

fujiy:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and data.extra_data and data.extra_data.fujiy
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    local all_cards = table.simpleClone(room.draw_pile)
    for _, info in ipairs(data.extra_data.fujiy) do
      if data.card.trueName == "slash" and info.trueName == "slash" then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      end
      if info.suit ~= Card.NoSuit and not player.dead then
        local card = table.filter(all_cards, function (id)
          return Fk:getCardById(id, true).suit == info.suit
        end)
        if #card > 0 then
          card = room:tableRandomPick(card)
          table.removeOne(all_cards, card)
          table.insert(cards, card)
        end
      end
    end
    if #cards > 0 and not player.dead then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, fujiy.name, nil, false, player)
    end
  end,
})

fujiy:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and
      data.extra_data and data.extra_data.fujiy and
      table.find(data.extra_data.fujiy, function(card)
        return card.trueName == "jink"
      end)
  end,
  on_use = function (self, event, target, player, data)
    local n = 0
    for _, info in ipairs(data.extra_data.fujiy) do
      if info.trueName == "jink" then
        n = n + 1
      end
    end
    player:drawCards(n, fujiy.name)
  end,
})

fujiy:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, fujiy.name, 0)
  end,
})

return fujiy
