
local fengshi = fk.CreateSkill{
  name = "m_heg__fengshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__fengshi"] = "锋矢",
  [":m_heg__fengshi"] = "<a href='m_heg_summon'>阵法技</a>，锁定技，你你每回合使用的第一张牌无距离限制。"..
  "若你围攻一名角色或被围攻，改为不可响应。",

  ["$m_heg__fengshi1"] = "大军压境，还不卸甲受降！",
  ["$m_heg__fengshi2"] = "放下兵器，饶你不死！",
}

local H = require "packages.hegemony.util"

fengshi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengshi.name) and
      table.find(player.room.alive_players, function (p)
        return H.inSiegeRelation(player, player, p) or H.inSiegeRelation(p, p, player)
      end) then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        return e.data.from == player
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end
})

fengshi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "m_heg__fengshi-turn", 1)
  end,
})

fengshi:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasShownSkill(fengshi.name) and card and player:getMark("m_heg__fengshi-turn") == 0 and
      not table.find(Fk:currentRoom().alive_players, function (p)
        return H.inSiegeRelation(player, player, p) or H.inSiegeRelation(p, p, player)
      end)
  end,
})

fengshi:addAcquireEffect(function (self, player, is_start, src)
  if not is_start then
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      if e.data.from == player then
        room:setPlayerMark(player, "m_heg__fengshi-turn", 1)
        return true
      end
    end, Player.HistoryTurn)
  end
end)

return fengshi
