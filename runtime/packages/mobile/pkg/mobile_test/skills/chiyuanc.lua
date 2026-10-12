local chiyuan = fk.CreateSkill {
  name = "chiyuanc",
}

Fk:loadTranslationTable{
  ["chiyuanc"] = "驰原",
  [":chiyuanc"] = "你每回合使用的第一张【杀】无距离限制且需要额外使用一张【闪】响应；出牌阶段限一次，你可以摸X张牌" ..
  "（X为当前连续被使用的红色牌数）。",

  ["#chiyuanc-active"] = "驰原：你可以摸%arg张牌",

  ["$chiyuanc1"] = "马力全开，红霆裂空！",
  ["$chiyuanc2"] = "千里疾驰，瞬息之间！",
}

chiyuan:addEffect("active", {
  prompt = function(self, player)
    return "#chiyuanc-active:::" .. (Fk:currentRoom():getBanner("chiyuanc_record") or 0)
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(chiyuan.name, Player.HistoryPhase) == 0 and
      (Fk:currentRoom():getBanner("chiyuanc_record") or 0) > 0
  end,
  target_num = 0,
  card_num = 0,
  target_filter = Util.FalseFunc,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    effect.from:drawCards(room:getBanner("chiyuanc_record") or 0, chiyuan.name)
  end,
})

chiyuan:addEffect(fk.AfterCardUseDeclared, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    local branches = {}
    if target == player then
      table.insert(branches, "chiyuanc_record")
    end

    if
      data.card.trueName == "slash" and
      target == player and
      player:hasSkill(chiyuan.name, true)
    then
      local room = player.room
      if player:getMark("chiyuan_slashed-turn") == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          if use.from == player and use.card.trueName == "slash" then
            room:setPlayerMark(player, "chiyuan_slashed-turn", e.id)
            return true
          end
        end, Player.HistoryTurn)
      end

      if
        player:hasSkill(chiyuan.name) and
        player:getMark("chiyuan_slashed-turn") == room.logic:getCurrentEvent().id
      then
        table.insert(branches, "chiyuanc_slash")
      end
    end

    if #branches > 0 then
      event:setCostData(self, { branches = branches })
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local branches = event:getCostData(self).branches
    if table.contains(branches, "chiyuanc_record") then
      local room = player.room
      if data.card.color == Card.Red then
        local chiyuanRecord = room:getBanner("chiyuanc_record") or 0
        chiyuanRecord = chiyuanRecord + 1
        room:setBanner("chiyuanc_record", chiyuanRecord)
      else
        room:setBanner("chiyuanc_record", 0)
      end
    end

    if table.contains(branches, "chiyuanc_slash") then
      data.extra_data = data.extra_data or {}
      data.extra_data.chiyuancWushuang = true
    end
  end,
})

chiyuan:addEffect(fk.TargetSpecified, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).chiyuancWushuang
  end,
  on_refresh = function(self, event, target, player, data)
    data:setResponseTimes(data:getResponseTimes() + 1)
  end,
})

chiyuan:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(chiyuan.name) and player:getMark("chiyuan_slashed-turn") == 0
  end,
})

chiyuan:addAcquireEffect(function(self, player, isStart)
  if not isStart then
    local room = player.room
    if player:getMark("chiyuan_slashed-turn") == 0 then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == player and use.card.trueName == "slash" then
          room:setPlayerMark(player, "chiyuan_slashed-turn", e.id)
          return true
        end
      end, Player.HistoryTurn)
    end

    if not room:getBanner("chiyuanc_record") then
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
        local count = 0
        if e.data.card.color == Card.Red then
          count = count + 1
        else
          room:setBanner("chiyuanc_record", count)
          return true
        end
      end, nil, Player.HistoryGame)
    end
  end
end)

return chiyuan
