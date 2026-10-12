local shibianw = fk.CreateSkill {
  name = "shibianw",
}

Fk:loadTranslationTable {
  ["shibianw"] = "识变",
  [":shibianw"] = "每轮开始时，你可以选择一名其他角色，本轮其攻击范围内的角色视为在你的攻击范围内，且你使用【杀】和普通锦囊牌" ..
      "可以指定其攻击范围内的一名角色为额外目标。",

  ["#shibianw-invoke"] = "识变：选择一名角色，本轮其攻击范围内的角色视为在你的攻击范围内",
  ["@[chara]shibianw-round"] = "识变",
  ["#shibianw-choose"] = "识变：你可以为%arg额外指定一个目标",

  ["$shibianw1"] = "将军得天时，吾不敢逆天而行。",
  ["$shibianw2"] = "懿拜明主，无愧于天地。",
}

shibianw:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shibianw.name) and #player.room:getOtherPlayers(player, false)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = shibianw.name,
      prompt = "#shibianw-invoke",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:setPlayerMark(player, "@[chara]shibianw-round", to.id)
  end,
})

shibianw:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@[chara]shibianw-round") == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[chara]shibianw-round", 0)
  end,
})

shibianw:addEffect("atkrange", {
  within_func = function(self, from, to)
    if from:getMark("@[chara]shibianw-round") ~= 0 then
      return Fk:currentRoom():getPlayerById(from:getMark("@[chara]shibianw-round")):inMyAttackRange(to, nil, nil, { self.name })
    end
  end,
})

shibianw:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shibianw.name) and
        (data.card.trueName == "slash" or data.card:isCommonTrick()) and
        player:getMark("@[chara]shibianw-round") ~= 0 and
        table.find(data:getExtraTargets({ bypass_distances = true }), function(p)
          return player.room:getPlayerById(player:getMark("@[chara]shibianw-round")):inMyAttackRange(p)
        end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_distances = true }), function(p)
      return room:getPlayerById(player:getMark("@[chara]shibianw-round")):inMyAttackRange(p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#shibianw-choose:::" .. data.card:toLogString(),
      skill_name = shibianw.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return shibianw
