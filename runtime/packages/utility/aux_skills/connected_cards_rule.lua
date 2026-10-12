local rule = fk.CreateSkill {
  name = "#connected_cards_rule",
}

Fk:loadTranslationTable{
  ["#connected_cards_rule"] = "弃置连接牌",
}

local U = require "packages.utility._base"

rule:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return table.find(data, function(move)
      if move.skillName ~= rule.name then
        return not not table.find(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId):getMark(U.ConnectedMark) > 0
        end)
      end
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId):getMark(U.ConnectedMark) > 0 then
          info.extra_data = info.extra_data or {}
          info.extra_data.isConnectedCard = true
        end
      end
    end
  end,
})

rule:addEffect(fk.AfterCardsMove, {
  priority = 0,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= player.room.players[1] then
      return false
    end

    return table.find(data, function(move)
      if
        move.skillName ~= rule.name and
        table.contains({ fk.ReasonUse, fk.ReasonResponse, fk.ReasonDiscard }, move.moveReason)
      then
        return not not table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand and (info.extra_data or {}).isConnectedCard
        end)
      end
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      local toThrow = table.filter(p:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark(U.ConnectedMark) > 0
      end)

      if #toThrow > 0 then
        room:throwCard(toThrow, rule.name, p, p)
      end
    end
  end,
})

rule:addEffect("visibility", {
  card_visible = function(self, player, card)
    local owner = Fk:currentRoom():getCardOwner(card)
    if owner == player then
      return true
    end

    if owner and
      owner ~= player and
      Fk:currentRoom():getCardArea(card) == Card.PlayerHand and
      card:getMark(U.ConnectedMark) > 0 then
      return true
    end
  end,
  move_visible = function(self, player, info, move)
    return (info.extra_data or {}).isConnectedCard
  end
})

return rule
