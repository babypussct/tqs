local diaodu = fk.CreateSkill{
  name = "diaodu",
}

Fk:loadTranslationTable{
  ["diaodu"] = "调度",
  [":diaodu"] = "当每回合首次与你势力相同的角色使用装备牌时，其可以摸一张牌。"..
  "出牌阶段开始时，你可以获得一名与你势力相同的角色装备区里的一张牌，然后你可以将此牌交给另一名角色。",

  ["#diaodu-invoke"] = "调度：你可以摸一张牌",
  ["#diaodu-choose"] = "调度：你可以获得与你势力相同的一名角色装备区里的一张牌",
  ["#diaodu-give"] = "调度：你可以将%arg交给另一名角色",

  ["$diaodu1"] = "诸军兵器战具，皆由我调配！",
  ["$diaodu2"] = "甲胄兵器，按我所说之法分发！",
}

local H = require "packages.hegemony.util"

diaodu:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(diaodu.name) and
      H.compareKingdomWith(target, player) and data.card.type == Card.TypeEquip and
      (player:hasShownSkill(diaodu.name) or target == player) and not target.dead then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return H.compareKingdomWith(e.data.from, player) and e.data.card.type == Card.TypeEquip
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = diaodu.name,
      prompt = "#diaodu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, diaodu.name)
  end,
})

diaodu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(diaodu.name) then return false end
    return target == player and target.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return H.compareKingdomWith(p, player) and #p:getCardIds("e") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player) and #p:getCardIds("e") > 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#diaodu-choose",
      skill_name = diaodu.name,
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
      flag = "e",
      skill_name = diaodu.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, diaodu.name, nil, true, player)
    if not table.contains(player:getCardIds("h"), card) then return end
    card = Fk:getCardById(card)
    local targets = room:getOtherPlayers(player, false)
    table.removeOne(targets, to)
    if #targets == 0 then return end
    to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#diaodu-give:::" .. card:toLogString(),
      skill_name = diaodu.name,
      cancelable = true,
    })
    if #to > 0 then
      to = to[1]
      room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, diaodu.name, nil, true, player)
    end
  end,
})

return diaodu
