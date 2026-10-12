local xiugeng = fk.CreateSkill {
  name = "xiugeng",
}

Fk:loadTranslationTable{
  ["xiugeng"] = "修耕",
  [":xiugeng"] = "回合开始时，你可以记录至多两名角色的手牌数。若如此做，这些角色的摸牌阶段开始时，若其手牌数：不大于记录值，" ..
  "则其摸两张牌；不小于记录值，则其手牌上限+1。",

  ["#xiugeng-choose"] = "修耕：你可记录至多两名角色的手牌数，这些角色将摸牌或加手牌上限",
  ["@xiugeng_record"] = "修耕",

  ["$xiugeng1"] = "既受此托，安可负曹公之任。",
  ["$xiugeng2"] = "相土处民，计民置吏，方可成屯田之功。",
  ["$xiugeng3"] = "百姓竟劝乐业，实是人间乐土。",
  ["$xiugeng4"] = "所幸风调雨顺，岁岁仓廪丰实。",
}

xiugeng:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiugeng.name)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 2,
        targets = player.room:getAlivePlayers(false),
        skill_name = xiugeng.name,
        prompt = "#xiugeng-choose",
      }
    )

    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      player.room:setPlayerMark(p, "@xiugeng_record", tostring(p:getHandcardNum()))
    end
  end,
})

xiugeng:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:getMark("@xiugeng_record") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local record = tonumber(player:getMark("@xiugeng_record"))
    room:setPlayerMark(player, "@xiugeng_record", 0)
    local n = player:getHandcardNum()
    if n <= record then
      player:drawCards(2, xiugeng.name)
    end

    if n >= record then
      room:addPlayerMark(player, MarkEnum.AddMaxCards)
    end
  end,
})

return xiugeng
