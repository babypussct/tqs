local yingbo = fk.CreateSkill {
  name = "yingbo",
}

Fk:loadTranslationTable{
  ["yingbo"] = "英博",
  [":yingbo"] = "当你使用伤害牌时，若本轮已有角色使用过，此牌造成的伤害改为火焰伤害且伤害+1；没有，则此牌不能被响应，"..
  "结算结束后你可以将之交给一名其他角色。",

  ["#yingbo-choose"] = "英博：你可以将%arg交给一名其他角色",

  ["$yingbo1"] = "上士之争，不在沙场而在方寸。",
  ["$yingbo2"] = "士别三日，当刮目相待，大兄何见事之晚乎！",
}

yingbo:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingbo.name) and
      data.card.is_damage_card
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    if #room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      return e.data.card.trueName == data.card.trueName and e.data ~= data
    end, nil, Player.HistoryRound) > 0 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.extra_data.yingbo1 = true
    else
      data.disresponsiveList = table.simpleClone(room.players)
      data.extra_data.yingbo2 = player
    end
  end,
})

yingbo:addEffect(fk.PreDamage, {
  can_refresh = function(self, event, target, player, data)
    if data.card and data.damageType ~= fk.FireDamage then
      local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      return (card_event.data.extra_data or {}).yingbo1
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageType = fk.FireDamage
  end,
})

yingbo:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      data.extra_data and data.extra_data.yingbo2 == player and
      player.room:getCardArea(data.card) == Card.Processing and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = yingbo.name,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#yingbo-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(data.card, Card.PlayerHand, to, fk.ReasonGive, yingbo.name, nil, true, player)
  end,
})

return yingbo
