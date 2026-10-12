
local xishi = fk.CreateSkill {
  name = "xishi",
}

Fk:loadTranslationTable {
  ["xishi"] = "析势",
  [":xishi"] = "每轮开始时，你可以选择一名其他角色，你观看并选择其一张手牌，其可以选择弃置至多两张手牌，"..
  "若未弃置你选择的牌，你获得此牌，且本轮你受到伤害后可以发动〖析势〗；若弃置你选择的牌，其摸一张牌。",

  ["#xishi-choose"] = "析势：观看一名角色的手牌并选择其中一张牌",
  ["#xishi-discard"] = "析势：弃置至多两张手牌，若未弃置 %src 选择的牌则其获得之，若弃置则你摸一张牌",
  ["@@xishi-round"] = "析势",

  ["$xishi1"] = "",
  ["$xishi2"] = "",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xishi.name,
      prompt = "#xishi-choose",
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
    local card = room:askToChooseCard(player, {
      target = to,
      flag = { card_data = { { to:toLogString(), to:getCardIds("h") } } },
      skill_name = xishi.name,
    })
    local cards = room:askToDiscard(to, {
      min_num = 1,
      max_num = 2,
      include_equip = false,
      skill_name = xishi.name,
      prompt = "#xishi-discard",
      cancelable = true,
    })
    if #cards > 0 and table.contains(cards, card) then
      if not to.dead then
        to:drawCards(1, xishi.name)
      end
    elseif not player.dead then
      room:setPlayerMark(player, "@@xishi-round", 1)
      if table.contains(to:getCardIds("h"), card) then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, xishi.name, nil, false, player)
      end
    end
  end,
}

xishi:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xishi.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xishi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xishi.name) and
      player:getMark("@@xishi-round") > 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return xishi
