local biluan = fk.CreateSkill{
  name = "ol__biluan",
}

Fk:loadTranslationTable{
  ["ol__biluan"] = "避乱",
  [":ol__biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为存活势力数）。",

  ["@ol__shixie_distance"] = "距离",
  ["#ol__biluan-invoke"] = "避乱：你可以弃一张牌，令其他角色计算与你距离+%arg",

  ["$ol__biluan1"] = "审视度度，以稳求进。",
  ["$ol__biluan2"] = "进退利弊，自当细细思量。",
}

biluan:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biluan.name) and player.phase == Player.Finish and
      not player:isNude() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:distanceTo(player) == 1
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = biluan.name,
      prompt = "#ol__biluan-invoke:::"..#kingdoms,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {choice = #kingdoms, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, biluan.name, player, player)
    if player.dead then return end
    local num = tonumber(player:getMark("@ol__shixie_distance")) + event:getCostData(self).choice
    room:setPlayerMark(player, "@ol__shixie_distance", num > 0 and "+"..num or num)
  end,
})
biluan:addEffect("distance", {
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ol__shixie_distance"))
    if num > 0 then
      return num
    end
  end,
})

return biluan
