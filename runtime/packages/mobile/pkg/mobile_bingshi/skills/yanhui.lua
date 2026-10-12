local yanhui = fk.CreateSkill {
  name = "yanhui",
}

Fk:loadTranslationTable{
  ["yanhui"] = "焰洄",
  [":yanhui"] = "当你使用牌指定第一个目标后，你可展示一名目标角色的一张手牌，若此牌本回合已被展示过，你弃置之。" ..
  "若如此做，此阶段结束时，你选择一项：1.对一名本阶段因此弃置过牌的角色造成1点火焰伤害；2.摸X张牌（X为本回合展示过牌的角色数）。",

  ["#yanhui-invoke"] = "焰洄：你可展示一名目标角色的一张手牌",
  ["#yanhui-choose"] = "焰洄：你可对一名满足条件的角色造成1点火焰伤害，或取消改为摸%arg张牌",
  ["#yanhui-force"] = "焰洄：对一名满足条件的角色造成1点火焰伤害",

  ["$yanhui1"] = "既有夺城之力，所图岂在一方！",
  ["$yanhui2"] = "你我同心共志，天下垂手可得！",
  ["$yanhui3"] = "便趁此胜，作气连捷！",
  ["$yanhui4"] = "敌势已弱，进起胜焰！",
  ["$yanhui5"] = "引子敬而定宏图，振长策共吞天下！",
  ["$yanhui6"] = "闻弦歌而知雅意，抚瑶琴以会群英！",
}

yanhui:addEffect(fk.TargetSpecified, {
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      data.firstTarget and
      player:hasSkill(yanhui.name) and
      table.find(data.use.tos, function(p)
        return not p:isKongcheng()
      end) and
      (player:getMark("@xiongzi-noclear") == 0 or player.room:getCurrent() == player)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(data.use.tos, function(p)
      return not p:isKongcheng()
    end)

    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = yanhui.name,
        prompt = "#yanhui-invoke",
      }
    )

    if #tos == 1 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = yanhui.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if room.logic:getCurrentEvent():findParent(GameEvent.Phase) then
      room:setPlayerMark(player, "yanhui_used-phase", 1)
    end

    local id = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "h",
        skill_name = skillName,
      }
    )

    local hasDisplayed = table.contains(room:getTag("yanhui_record-turn") or {}, id)
    to:showCards(id, player)
    if hasDisplayed then
      room:throwCard(id, skillName, to, player)
    end
  end
})

yanhui:addEffect(fk.EventPhaseEnd, {
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("yanhui_used-phase") > 0 and player:isAlive()
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = yanhui.name
    local room = player.room

    local targets = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if
          move.from and
          move.moveReason == fk.ReasonDiscard and
          move.skillName == skillName and
          move.from:isAlive()
        then
          table.insertIfNeed(targets, move.from)
        end
      end
    end, Player.HistoryPhase)

    local record = #(room:getTag("yanhui_players-turn") or {})
    if #targets == 0 and record == 0 then
      return false
    end

    local optionSeq = player:getMark("@xiongzi-noclear")
    local tos = {}
    if optionSeq ~= "xiongzi_1" and #targets > 0 then
      local prompt = optionSeq ~= "xiongzi_2" and ("#yanhui-choose:::" .. record) or "#yanhui-force"
      tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = skillName,
          prompt = prompt,
          cancelable = optionSeq ~= "xiongzi_2",
        }
      )
    end

    if optionSeq == "xiongzi_2" and #tos == 0 then
      return false
    end

    if #tos == 0 then
      player:drawCards(record, skillName)
    else
      room:damage{
        from = player,
        to = tos[1],
        damage = 1,
        damageType = fk.FireDamage,
        skillName = skillName,
      }
    end
  end,
})

yanhui:addEffect(fk.CardShown, {
  can_refresh = function (self, event, target, player, data)
    return data.from == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local record = room:getTag("yanhui_record-turn") or {}
    table.insertTableIfNeed(record, data.cardIds)
    room:setTag("yanhui_record-turn", record)

    record = room:getTag("yanhui_players-turn") or {}
    table.insertIfNeed(record, player.id)
    room:setTag("yanhui_players-turn", record)
  end,
})

return yanhui
