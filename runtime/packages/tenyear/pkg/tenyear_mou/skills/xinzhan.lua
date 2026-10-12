
local xinzhan = fk.CreateSkill {
  name = "ty__xinzhan",
}

Fk:loadTranslationTable{
  ["ty__xinzhan"] = "心战",
  [":ty__xinzhan"] = "你每回合首次使用【杀】或普通锦囊牌指定其他角色为唯一目标时（每回合各一次），"..
  "你可以猜测此牌是否被响应。此牌结算完毕后，若你猜对，观看此牌目标的手牌并获得其一张牌；"..
  "若你猜错，其视为对你使用【决斗】。",

  ["#ty__xinzhan-choice"] = "心战：猜测你对 %dest 使用的%arg是否会被响应",
  ["#ty__xinzhan-prey"] = "心战：获得 %dest 一张牌",

  ["$ty__xinzhan1"] = "",
  ["$ty__xinzhan2"] = "",
}

xinzhan:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xinzhan.name) and
      data.to ~= player and data:isOnlyTarget(data.to) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == player and #use.tos == 1 and use.tos[1] ~= player then
            if data.card.trueName == "slash" then
              return use.card.trueName == "slash"
            else
              return use.card:isCommonTrick()
            end
          end
        end, Player.HistoryTurn)
        return #use_events == 1 and use_events[1].id == use_event.id
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "yes", "no", "Cancel" },
      skill_name = xinzhan.name,
      prompt = "#ty__xinzhan-choice::"..data.to.id..":"..data.card:toLogString(),
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { data.to }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__xinzhan = { player, data.to, event:getCostData(self).choice }
  end,
})

xinzhan:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.extra_data and (data.extra_data.ty__xinzhan or {})[1] == player and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to, choice = data.extra_data.ty__xinzhan[2], data.extra_data.ty__xinzhan[3]
    if (data.extra_data.ty__xinzhan_responded and choice == "yes") or
      (data.extra_data.ty__xinzhan_responded == nil and choice == "no") then
      if not to:isNude() then
        room:doIndicate(player, { to })
        local card_data = {}
        if not to:isKongcheng() then
          table.insert(card_data, { "$Hand", to:getCardIds("h") })
        end
        if #to:getCardIds("e") > 0 then
          table.insert(card_data, { "$Equip", to:getCardIds("e") })
        end
        local card = room:askToChooseCard(player, {
          target = to,
          flag = { card_data = card_data },
          skill_name = xinzhan.name,
          prompt = "#ty__xinzhan-prey::"..to.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, xinzhan.name, nil, false, player)
      end
    else
      --local card = room:getCardsFromPileByRule("slash")
      --if #card > 0 then
      --  room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, xinzhan.name, nil, false, player)
      --end
      if not player.dead and not to.dead then
        room:useVirtualCard("duel", {}, to, player, xinzhan.name, true)
      end
    end
  end,
})

local spec = {
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event == nil then return end
    local use = use_event.data
    use.extra_data = use.extra_data or {}
    if use.extra_data.ty__xinzhan then
      use.extra_data.ty__xinzhan_responded = true
    end
  end,
}

xinzhan:addEffect(fk.AfterAskForCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.eventData and data.result and data.result.from == player
  end,
  on_refresh = spec.on_refresh,
})

xinzhan:addEffect(fk.AfterAskForCardResponse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.eventData and data.result
  end,
  on_refresh = spec.on_refresh,
})

xinzhan:addEffect(fk.AfterAskForNullification, {
  can_refresh = function(self, event, target, player, data)
    return data.eventData and data.result and data.result.from == player
  end,
  on_refresh = spec.on_refresh,
})

return xinzhan
