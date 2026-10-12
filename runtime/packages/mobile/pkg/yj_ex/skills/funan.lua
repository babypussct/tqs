
local funan = fk.CreateSkill {
  name = "mobile__funan",
  dynamic_desc = function (self, player)
    if player:getMark("mobile__funan_update") > 0 then
      return "mobile__funan_update"
    end
  end
}

Fk:loadTranslationTable{
  ["mobile__funan"] = "复难",
  [":mobile__funan"] = "其他角色使用或打出牌响应你使用的牌时，你可以获得其使用或打出的牌。<br>"..
  "⬤　二级：其他角色使用或打出牌响应你使用的牌时，你可以获得其使用或打出的牌；你使用以此法获得的牌结算结束后，"..
  "若没有其他角色响应此牌，你摸一张牌。",

  [":mobile__funan_update"] = "其他角色使用或打出牌响应你使用的牌时，你可以获得其使用或打出的牌；你使用以此法获得的牌结算结束后，"..
  "若没有其他角色响应此牌，你摸一张牌。",

  ["#mobile__funan-invoke"] = "复难：你可以获得 %dest 使用的%arg",
  ["@@mobile__funan-inhand"] = "复难",

  ["$mobile__funan1"] = "有来有往，方为君子之辩。",
  ["$mobile__funan2"] = "公言虽妙，却有自相矛盾之处，容我言之。",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(funan.name) and target ~= player and
      data.responseToEvent and data.responseToEvent.from == player and
      data.responseToEvent.card and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = funan.name,
      prompt = "#mobile__funan-invoke::"..target.id..":"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, funan.name, nil, true, player,
      "@@mobile__funan-inhand")
  end,

  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event == nil then return end
    local use = use_event.data
    use.extra_data = use.extra_data or {}
    if use.extra_data.mobile__funan and use.extra_data.mobile__funan ~= player then
      use.extra_data.mobile__funan = nil
    end
  end,
}

funan:addEffect(fk.CardUsing, spec)
funan:addEffect(fk.CardResponding, spec)

funan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(funan.name) and player:getMark("mobile__funan_update") > 0 and
      data.extra_data and data.extra_data.mobile__funan == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, funan.name)
  end,
})

funan:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@mobile__funan-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.mobile__funan = player
  end,
})

funan:addEffect(fk.AfterAskForCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.eventData and data.result and data.result.from == player
  end,
  on_refresh = spec.on_refresh,
})
funan:addEffect(fk.AfterAskForCardResponse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.eventData and data.result
  end,
  on_refresh = spec.on_refresh,
})
funan:addEffect(fk.AfterAskForNullification, {
  can_refresh = function(self, event, target, player, data)
    return data.eventData and data.result and data.result.from == player
  end,
  on_refresh = spec.on_refresh,
})

funan:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "mobile__funan_update", 0)
end)

return funan
