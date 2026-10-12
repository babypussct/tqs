local lvren = fk.CreateSkill {
  name = "os__lvren",
}

Fk:loadTranslationTable{
  ["os__lvren"] = "履刃",
  [":os__lvren"] = "当你对其他角色造成伤害时，若其没有“刃”，你令其获得1枚“刃”标记。当你使用伤害牌选择目标后，" ..
  "你可以令一名有“刃”的角色也成为目标并移去其“刃”标记。你拼点时，每有一名角色，你的拼点牌点数+2。",

  ["@@os__blade"] = "刃",
  ["#os__lvren-choose"] = "履刃：你可以移去一名角色的“刃”标记，令其成为此%arg额外目标",

  ["$os__lvren1"] = "坚甲利刃，破之如鲁缟！",
  ["$os__lvren2"] = "攻城破阵，如履平地！"
}

lvren:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lvren.name) and
      data.card.is_damage_card and
      table.find(data:getExtraTargets({ bypass_times = true, bypass_distances = true }), function (p)
        return p:getMark("@@os__blade") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_times = true, bypass_distances = true }), function (p)
      return p:getMark("@@os__blade") > 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__lvren-choose:::"..data.card:toLogString(),
      skill_name = lvren.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    data:addTarget(to)
    room:removePlayerMark(to, "@@os__blade")
  end,
})

lvren:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lvren.name) and
      data.to:getMark("@@os__blade") == 0 and data.to ~= player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(data.to, "@@os__blade")
  end,
})

lvren:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lvren.name) and (data.from == player or table.contains(data.tos, player))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changePindianNumber(data, player, 2 * (#data.tos + 1), lvren.name)
  end,
})

return lvren
