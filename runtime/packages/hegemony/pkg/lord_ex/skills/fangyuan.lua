local fangyuan = fk.CreateSkill {
  name = "ld__fangyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__fangyuan"] = "方圆",
  [":ld__fangyuan"] = "阵法技，①若你是围攻角色，此围攻关系中围攻角色手牌上限+1，被围攻角色手牌上限-1。②结束阶段，若你是被围攻角色，你视为对此围攻关系中一名围攻角色使用一张无距离限制的【杀】。",
  ["#ld__fangyuan-choose"] = "方圆：选择此围攻关系中的一名围攻角色，视为对其使用一张【杀】",

  ["$ld__fangyuan1"] = "布阵合围，滴水不漏，待敌自溃。",
  ["$ld__fangyuan2"] = "乘敌阵未猛，待我斩将易旗，先奋士气。",
}

local H = require "packages.hegemony.util"

fangyuan:addEffect("arraysummon", {
  array_type = "siege",
})

fangyuan:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local prev_player = player:getLastAlive()
    local next_player = player:getNextAlive()
    return player:hasSkill(fangyuan.name) and player.phase == Player.Finish and
    H.inSiegeRelation(prev_player, next_player, player) and player:hasShownSkill(fangyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local prev_player = player:getLastAlive()
    local next_player = player:getNextAlive()
    local targets = {}
    local slash = Fk:cloneCard("slash")
    if not player:isProhibited(prev_player, slash) then
      table.insert(targets, prev_player)
    end
    if not player:isProhibited(next_player, slash) then
      table.insert(targets, next_player)
    end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ld__fangyuan-choose",
      skill_name = fangyuan.name,
      cancelable = false,
    })
    local to = tos[1]
    player:broadcastSkillInvoke(fangyuan.name)
    room:useVirtualCard("slash", nil, player, to, fangyuan.name, true)
  end,
})

local fangyuan_spec = {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(fangyuan.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local ret = player:hasSkill(fangyuan.name)
    local prev = player:getLastAlive()
    local next = player:getNextAlive()
    local clear = true
    if ret and H.inSiegeRelation(prev:getLastAlive(), player, prev) then
      room:setPlayerMark(prev:getLastAlive(), "ld__fangyuan_card", 1)
      room:setPlayerMark(player, "ld__fangyuan_card", 1)
      room:setPlayerMark(prev, "ld__fangyuan_card", -1)
      clear = false
    end
    if ret and H.inSiegeRelation(player, next:getNextAlive(), next) then
      room:setPlayerMark(player, "ld__fangyuan_card", 1)
      room:setPlayerMark(next:getNextAlive(), "ld__fangyuan_card", 1)
      room:setPlayerMark(next, "ld__fangyuan_card", -1)
      clear = false
    end
    if clear == true then
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "ld__fangyuan_card", 0)
      end
    end
  end,
}

fangyuan:addEffect(fk.GeneralHidden, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not player:hasShownSkill(fangyuan.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "ld__fangyuan_card", 0)
    end
  end,
})

fangyuan:addLoseEffect(function(self, player, is_death)
  for _, p in ipairs(player.room.alive_players) do
    player.room:setPlayerMark(p, "ld__fangyuan_card", 0)
  end
end)

fangyuan:addEffect(fk.TurnStart, fangyuan_spec)
fangyuan:addEffect(fk.GeneralRevealed, fangyuan_spec)
fangyuan:addEffect(fk.EventAcquireSkill, fangyuan_spec)
fangyuan:addEffect(H.PlayerRemoved, fangyuan_spec)
fangyuan:addEffect(fk.Death, fangyuan_spec)

fangyuan:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("ld__fangyuan_card")
  end,
})

return fangyuan
