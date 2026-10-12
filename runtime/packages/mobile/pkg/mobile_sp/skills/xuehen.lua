local xuehen = fk.CreateSkill {
  name = "mobile__xuehen",
  dynamic_desc = function (self, player, lang)
    if player:getMark("mobile__xuehen-phase") > 0 or player:getMark(self.name) > 0 then
      return "mobile__xuehen_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["mobile__xuehen"] = "雪恨",
  [":mobile__xuehen"] = "当你每回合首次造成或受到伤害后，你可以展示至多X张手牌（X为你已损失体力值），这些牌视为无次数限制的【杀】，"..
  "直到你使用这些牌造成伤害。",

  [":mobile__xuehen_update"] = "当你每回合首次造成或受到伤害后，你可以展示至多X张手牌（X为你已损失体力值），这些牌视为无次数限制的【杀】，"..
  "直到你使用这些牌造成伤害。当你使用以此法转化的【杀】结算结束后，你摸一张牌。",

  ["#mobile__xuehen-invoke"] = "雪恨：展示至多%arg张手牌，这些牌视为无次数限制的【杀】",
  ["@@mobile__xuehen-inhand"] = "雪恨",

  ["$mobile__xuehen1"] = "国仇家恨，岂惧山阻水隔，荆棘载途！",
  ["$mobile__xuehen2"] = "理红妆，贴花黄，无碍征战疆场！",
}

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = player:getLostHp(),
      include_equip = false,
      skill_name = xuehen.name,
      prompt = "#mobile__xuehen-invoke:::"..player:getLostHp(),
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    player:showCards(cards)
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@mobile__xuehen-inhand", 1)
    end
    player:filterHandcards()
  end,
}
xuehen:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xuehen.name) and player:isWounded() and not player:isKongcheng() then
      local damage_events = player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn)
      return #damage_events > 0 and damage_events[1].data == data
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
xuehen:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xuehen.name) and player:isWounded() and not player:isKongcheng() then
      local damage_events = player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.to == player
      end, Player.HistoryTurn)
      return #damage_events > 0 and damage_events[1].data == data
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xuehen:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@mobile__xuehen-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

xuehen:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@mobile__xuehen-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = xuehen.name
    return c
  end,
})

xuehen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@mobile__xuehen-inhand") > 0
  end,
})

xuehen:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, xuehen.name)
  end,
  on_refresh = function (self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@mobile__xuehen-inhand", 0)
    end
  end,
})

xuehen:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, xuehen.name) and not player.dead and
      (player:getMark("mobile__xuehen-phase") > 0 or player:getMark(xuehen.name) > 0)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1, xuehen.name)
    if not player.dead and player:usedEffectTimes(self.name, Player.HistoryGame) > 1 then
      room:setPlayerMark(player, "mobile__xuehen-phase", 0)
      room:setPlayerMark(player, xuehen.name, 1)
    end
  end,
})

xuehen:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, xuehen.name, 0)
  room:setPlayerMark(player, "mobile__xuehen-phase", 0)
end)

return xuehen
