local bifeng = fk.CreateSkill {
  name = "bifeng",
}

Fk:loadTranslationTable{
  ["bifeng"] = "避锋",
  [":bifeng"] = "当你成为基本牌或普通锦囊牌的目标时，若目标数不大于4，则你可取消之。若如此做，此牌结算结束后，" ..
  "若没有其他角色响应过此牌，则你失去1点体力，否则你摸两张牌。",

  ["#bifeng-invoke"] = "避锋：你可以取消 %src 对你使用的%arg，结算后你失去体力或摸牌",

  ["$bifeng1"] = "事已至此，当速禀南阙之急。",
  ["$bifeng2"] = "陛下今日所为，实令臣民失望。",
  ["$bifeng3"] = "众士暂避其锋，万不可冲撞圣驾。",
}

bifeng:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bifeng.name) and not data.cancelled and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      #data.use.tos < 5
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = bifeng.name,
      prompt = "#bifeng-invoke:"..data.from.id.."::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    local users = data.extra_data.bifeng or {}
    table.insertIfNeed(users, player)
    data.extra_data.bifeng = users
    data:cancelCurrentTarget()
  end,
})
bifeng:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.bifeng and
      table.contains(data.extra_data.bifeng, player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if useEvent == nil then return end
    if #useEvent:searchEvents(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from ~= player and use.responseToEvent and use.responseToEvent.card == data.card
      end) > 0 or
      #useEvent:searchEvents(GameEvent.RespondCard, 1, function(e)
        local response = e.data
        return response.from ~= player and response.responseToEvent and response.responseToEvent.card == data.card
      end) > 0
    then
      player:drawCards(2, bifeng.name)
    else
      room:loseHp(player, 1, bifeng.name)
    end
  end,
})

return bifeng
