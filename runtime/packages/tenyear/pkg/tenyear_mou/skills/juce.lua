local juce = fk.CreateSkill {
  name = "juce",
}

Fk:loadTranslationTable{
  ["juce"] = "举策",
  [":juce"] = "你于回合内首次使用基本牌或普通锦囊牌指定目标时，你可以多选择一个目标。"..
  "若如此做，该角色下回合使用的第一张基本牌或普通锦囊牌额外指定你为目标。",

  ["#juce-choose"] = "举策：你可以为%arg增加一个目标，其下回合第一次使用牌额外指定你为目标",
  ["@@juce"] = "举策",

  ["$juce1"] = "敌势凶猛，然分兵袭扰可破之。",
  ["$juce2"] = "均兵而战，曹军必乱。",
}

juce:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(juce.name) and data.firstTarget and room.current == data.from and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      if player ~= data.from and
        (data.from.dead or not table.contains(data.from:getTableMark("@@juce"), player)) then
        return false
      end
      local logic = room.logic
      local use_e = logic:getCurrentEvent()
      local mark = data.from:getMark("juce_record-turn")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == data.from and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
            mark = e.id
            room:setPlayerMark(data.from, "juce_record-turn", mark)
            return true
          end
        end, Player.HistoryTurn)
      end
      if mark == use_e.id then
        local tos = data:getExtraTargets({ bypass_distances = true })
        if player == data.from then
          return table.find(tos, function(p)
            return p ~= player
          end)
        else
          return table.contains(tos, player)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if player == data.from then
      local tos = data:getExtraTargets({ bypass_distances = true })
      table.removeOne(tos, player)
      local to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#juce-choose:::"..data.card:toLogString(),
        skill_name = juce.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, { tos = to })
        return true
      end
    else
      event:setCostData(self, { mute = true })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player == data.from then
      local to = event:getCostData(self).tos[1]
      data:addTarget(to)
      player.room:addTableMarkIfNeed(to, "@@juce", player)
    else
      data:addTarget(player)
    end
  end,
})

juce:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@juce") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@juce", 0)
  end,
})

return juce
