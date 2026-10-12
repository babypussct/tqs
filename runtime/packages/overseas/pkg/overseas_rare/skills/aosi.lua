local aosi = fk.CreateSkill{
  name = "os_xing__aosi",
  tags = {Skill.Compulsory},
}

Fk:loadTranslationTable{
  ["os_xing__aosi"] = "骜肆",
  [":os_xing__aosi"] = "锁定技，当你于出牌阶段对一名在你攻击范围内的其他角色造成伤害后，" .. 
    "你于此阶段对其使用牌无次数限制。你于出牌阶段使用的第X张牌不能被响应（X为游戏轮数）。",

  ["@@os_xing__aosi-phase"] = "骜肆",

  ["$os_xing__aosi1"] = "舐刀吮血，杀人如麻！",
  ["$os_xing__aosi2"] = "衮衮诸公，皆不如我一人乎？",
}

aosi:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aosi.name) and player.phase == Player.Play and
      data.to:getMark("@@os_xing__aosi-phase") == 0 and not data.to.dead and player:inMyAttackRange(data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@@os_xing__aosi-phase", 1)
    room:addTableMark(player, "os_xing__aosi-phase", data.to.id)
  end,
})
aosi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("os_xing__aosi-phase"), to.id)
  end,
})

aosi:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if target ~= player or not player:hasSkill(aosi.name) or player.phase ~= Player.Play then return false end
    local n = player.room:getBanner("RoundCount") or 0
    return #player.room.logic:getEventsOfScope(GameEvent.UseCard, n + 1, function(e)
      return e.data.from == player
    end, Player.HistoryPhase) == n
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end
})

return aosi
