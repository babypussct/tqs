local mobileXionghuo = fk.CreateSkill {
  name = "mobile__xionghuo",
}

Fk:loadTranslationTable{
  ["mobile__xionghuo"] = "凶镬",
  [":mobile__xionghuo"] = "游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，"..
  "你对有此标记的其他角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项："..
  "1.受到1点火焰伤害且本回合不能对你使用【杀】；"..
  "2.流失1点体力且本回合手牌上限-1；"..
  "3.你随机获得其一张手牌和一张装备区里的牌。",

  ["@mobile__baoli"] = "暴戾",
  ["#mobile__xionghuo-active"] = "发动 凶镬，将“暴戾”交给其他角色",

  ["$mobile__xionghuo1"] = "战场上的懦夫，可不会有好结局！",
  ["$mobile__xionghuo2"] = "用最残忍的方式，碾碎敌人！",
}

mobileXionghuo:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__xionghuo-active",
  can_use = function(self, player)
    return player:getMark("@mobile__baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("@mobile__baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:removePlayerMark(player, "@mobile__baoli", 1)
    room:addPlayerMark(target, "@mobile__baoli", 1)
  end,
})

mobileXionghuo:addEffect(fk.GameStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mobileXionghuo.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@mobile__baoli", 3)
  end,
})

mobileXionghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mobileXionghuo.name) and
      data.to ~= player and
      data.to:getMark("@mobile__baoli") > 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

mobileXionghuo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(mobileXionghuo.name) and
      target:getMark("@mobile__baoli") > 0 and
      target.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileXionghuo.name
    local room = player.room
    room:setPlayerMark(target, "@mobile__baoli", 0)
    local rand = math.random(1, target:isNude() and 2 or 3)
    if rand == 1 then
      room:damage {
        from = player,
        to = target,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = skillName,
      }
      if target:isAlive() then
        room:addTableMark(target, "mobile__xionghuo_prohibit-turn", player.id)
      end
    elseif rand == 2 then
      room:loseHp(target, 1, skillName)
      if target:isAlive() then
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      end
    else
      local cards = room:tableRandomPick(target:getCardIds("h"), 1)
      table.insertTable(cards, room:tableRandomPick(target:getCardIds("e"), 1))
      room:obtainCard(player, cards, false, fk.ReasonPrey, player)
    end
  end,
})

mobileXionghuo:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card.trueName == "slash" and from and table.contains(from:getTableMark("mobile__xionghuo_prohibit-turn"), to.id)
  end,
})

mobileXionghuo:addLoseEffect(function (self, player)
  if
    table.every(player.room.alive_players, function (p)
      return not p:hasSkill(mobileXionghuo.name, true)
    end)
  then
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("@mobile__baoli") > 0 then
        player.room:setPlayerMark(p, "@mobile__baoli", 0)
      end
    end
  end
end)

return mobileXionghuo
