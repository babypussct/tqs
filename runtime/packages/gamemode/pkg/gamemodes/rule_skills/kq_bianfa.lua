local bianfa = fk.CreateSkill {
  name = "#kq__bianfa",
}

Fk:loadTranslationTable{
  ["#kq__bianfa"] = "商鞅变法",
  [":#kq__bianfa"] = "牌堆中加入3张【商鞅变法】；若场上有商鞅，则商鞅使用的【商鞅变法】的目标上限+1。",

  ["#kq__bianfa-choose"] = "你可以为可以为%arg额外指定一个目标",
}

bianfa:addEffect(fk.GameStart, {
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for i in ipairs({5, 7, 9}) do
      local id = room:printCard("shangyang_reform", Card.Spade, i).id
      table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
    end
    room:syncDrawPile()
  end,
})

bianfa:addEffect(fk.AfterCardTargetDeclared, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and
      (Fk.generals[player.general].trueName == "shangyang" or (Fk.generals[player.deputyGeneral] or {}).trueName == "shangyang") and
      data.card.name == "shangyang_reform" and #data:getExtraTargets() > 0
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets(),
      skill_name = bianfa.name,
      prompt = "#kq__bianfa-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      player:broadcastSkillInvoke("qin__bianfa")
      data:addTarget(to[1])
    end
  end,
})

return bianfa
