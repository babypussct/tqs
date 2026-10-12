local H = require "packages.hegemony.util"

local paoxiao = fk.CreateSkill {
  name = "xuanhuo__hs__paoxiao",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return "hs__paoxiao_shouyue"
    else
      return "xuanhuo__hs__paoxiao"
    end
  end,
}

paoxiao:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    if card and player:hasSkill(self.name) and skill.trueName == "slash_skill"
        and scope == Player.HistoryPhase then
      return true
    end
  end,
})
paoxiao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(paoxiao.name) or data.card.trueName ~= "slash" then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
      local use = e.data
      return use.from == player and use.card.trueName == "slash"
    end, Player.HistoryTurn)
    return #events == 2 and events[2].id == player.room.logic:getCurrentEvent().id
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, paoxiao.name)
  end,
})
paoxiao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(paoxiao.name) and data.card.trueName == "slash"
        and not data.extraUse and player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("hs__paoxiao")
    room:doAnimate("InvokeSkill", {
      name = "paoxiao",
      player = player.id,
      skill_type = "offensive",
    })
  end,
})
paoxiao:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and player:hasSkill(paoxiao.name)
        and H.hasHegLordSkill(player.room, player, "shouyue") and data.to:isAlive()
  end,
  on_refresh = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

Fk:loadTranslationTable {
  ["xuanhuo__hs__paoxiao"] = "咆哮",
  [":xuanhuo__hs__paoxiao"] = "锁定技，你使用【杀】无次数限制。当你于一个回合内使用第二张【杀】时，你摸一张牌。",
}

return paoxiao
