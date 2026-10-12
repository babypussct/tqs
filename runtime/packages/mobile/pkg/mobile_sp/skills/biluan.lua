local biluan = fk.CreateSkill{
  name = "biluan",
}

Fk:loadTranslationTable{
  ["biluan"] = "避乱",
  [":biluan"] = "摸牌阶段开始时，若有角色与你的距离为1，你可以放弃摸牌，令其他角色计算与你的距离+X（X为存活势力数）。",

  ["@shixie_distance"] = "距离",
  ["#biluan-invoke"] = "避乱：你可以放弃摸牌，令其他角色计算与你距离+%arg",

  ["$biluan1"] = "身处乱世，自保足矣。",
  ["$biluan2"] = "避一时之乱，求长世安稳。",
}

biluan:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biluan.name) and player.phase == Player.Draw and
      not data.phase_end and
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
    if room:askToSkillInvoke(player, {
      skill_name = biluan.name,
      prompt = "#biluan-invoke:::"..#kingdoms,
    }) then
      event:setCostData(self, {choice = #kingdoms})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local num = tonumber(player:getMark("@shixie_distance")) + event:getCostData(self).choice
    room:setPlayerMark(player, "@shixie_distance", num > 0 and "+"..num or num)
  end,
})

biluan:addEffect("distance", {
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@shixie_distance"))
    if num > 0 then
      return num
    end
  end,
})

return biluan
