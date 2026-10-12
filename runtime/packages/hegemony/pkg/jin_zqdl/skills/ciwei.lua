local ciwei = fk.CreateSkill{
  name = "heg__ciwei",
}

Fk:loadTranslationTable{
  ["heg__ciwei"] = "慈威",
  [":heg__ciwei"] = "你的回合内，当其他角色使用牌时，若场上有本回合使用或打出过牌且不与其势力相同的其他角色，你可以弃置一张牌令此牌无效"..
  "（取消所有目标）。",

  ["#heg__ciwei-invoke"] = "慈威：你可以弃置一张牌，取消 %dest 使用的%arg",

  ["$heg__ciwei1"] = "乃家乃邦，是则是效。",
  ["$heg__ciwei2"] = "其慈有威，不舒不暴。",
}

local H = require "packages.hegemony.util"

ciwei:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(ciwei.name) and player.room.current == player and not player:isNude() then
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from ~= player and not use.from.dead and H.compareKingdomWith(use.from, target, true)
      end, Player.HistoryTurn) > 0 then
        return true
      end
      if #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
        local use = e.data
        return use.from ~= player and not use.from.dead and H.compareKingdomWith(use.from, target, true)
      end, Player.HistoryTurn) > 0 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ciwei.name,
      prompt = "#heg__ciwei-invoke::"..target.id..":"..data.card:toLogString(),
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.toCard = nil
    data:removeAllTargets()
    room:throwCard(event:getCostData(self).cards, ciwei.name, player, player)
  end,
})

return ciwei
