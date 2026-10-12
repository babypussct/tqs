local lingshu = fk.CreateSkill {
  name = "lingshu",
}

Fk:loadTranslationTable{
  ["lingshu"] = "领戍",
  [":lingshu"] = "若你当前回合未造成或受到过伤害，你可以将一张非基本牌当任意基本牌使用或打出。"..
  "你每回合首次造成或受到伤害后，可以随机获得一张本回合进入弃牌堆的牌。",

  ["#lingshu"] = "领戍：将一张非基本牌当任意基本牌使用或打出",
  ["#lingshu-invoke"] = "领戍：你可以随机获得一张本回合进入弃牌堆的牌",

  ["$lingshu1"] = "难道我，不知兵吗！",
  ["$lingshu2"] = "乌巢有我镇守，本初大可放心！",
}

lingshu:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#lingshu",
  handly_pile = true,
  filter_pattern = function(self, player, card_name, selected)
    return {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|.|.|^basic",
    }
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(lingshu.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, lingshu.name, cards)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("lingshu-turn") == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("lingshu-turn") == 0
  end,
})

local spec = {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lingshu.name) then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return event == fk.Damage and e.data.from == player or e.data.to == player
      end, Player.HistoryTurn)
      if #damage_events == 1 and damage_events[1].data == data then
        return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if move.toArea == Card.DiscardPile then
              for _, info in ipairs(move.moveInfo) do
                if table.contains(player.room.discard_pile, info.cardId) then
                  return true
                end
              end
            end
          end
        end, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lingshu.name,
      prompt = "#lingshu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
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
    room:moveCardTo(room:tableRandomPick(cards), Card.PlayerHand, player, fk.ReasonJustMove, lingshu.name, nil, true, player)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "lingshu-turn", 1)
  end,
}
lingshu:addEffect(fk.Damage, spec)
lingshu:addEffect(fk.Damaged, spec)

lingshu:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    local room = player.room
    if #room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        return damage.from == player or damage.to == player
      end, Player.HistoryTurn) > 0 then
      room:setPlayerMark(player, "lingshu-turn", 1)
    end
  end
end)

return lingshu
