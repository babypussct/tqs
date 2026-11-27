
local fangyuan = fk.CreateSkill {
  name = "nos_heg__fangyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["nos_heg__fangyuan"] = "方圆",
  [":nos_heg__fangyuan"] = "阵法技，若你是围攻角色，此围攻关系中围攻角色手牌上限+1，被围攻角色手牌上限-1。"..
  "结束阶段，若你是被围攻角色，你视为对此围攻关系中一名围攻角色使用一张【杀】。",

  ["#nos_heg__fangyuan-choose"] = "方圆：选择此围攻关系中的一名围攻角色，视为对其使用一张【杀】",

  ["$nos_heg__fangyuan1"] = "布阵合围，滴水不漏，待敌自溃。",
  ["$nos_heg__fangyuan2"] = "乘敌阵未猛，待我斩将易旗，先奋士气。",
}

local H = require "packages.hegemony.util"

fangyuan:addEffect("arraysummon", {
  array_type = "siege",
})

fangyuan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(fangyuan.name) and player.phase == Player.Finish and
      H.inSiegeRelation(player:getLastAlive(), player:getNextAlive(), player) and
      table.find({ player:getLastAlive(), player:getNextAlive() }, function (p)
        return not player:isProhibited(p, Fk:cloneCard("slash", nil, nil, fangyuan.name))
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter({ player:getLastAlive(), player:getNextAlive() }, function (p)
      return not player:isProhibited(p, Fk:cloneCard("slash", nil, nil, fangyuan.name))
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#nos_heg__fangyuan-choose",
      skill_name = fangyuan.name,
      cancelable = false,
    })[1]
    room:useVirtualCard("slash", nil, player, to, fangyuan.name, true)
  end,
})

fangyuan:addEffect("maxcards", {
  correct_func = function(self, player)
    local n = 0
    local next_player, last_player = player:getNextAlive(), player:getLastAlive()
    if player:hasShownSkill(fangyuan.name) and
      (H.inSiegeRelation(player, next_player:getNextAlive(), next_player) or
      H.inSiegeRelation(last_player:getLastAlive(), player, last_player)) then
      n = n + 1
    end
    if next_player:getNextAlive():hasShownSkill(fangyuan.name) and
      H.inSiegeRelation(player, next_player:getNextAlive(), next_player) then
      n = n + 1
    end
    if last_player:getLastAlive():hasShownSkill(fangyuan.name) and
      H.inSiegeRelation(last_player:getLastAlive(), player, last_player) then
      n = n + 1
    end
    if next_player:hasShownSkill(fangyuan.name) and
      H.inSiegeRelation(last_player, next_player, player) then
      n = n - 1
    end
    if last_player:hasShownSkill(fangyuan.name) and
      H.inSiegeRelation(last_player, next_player, player) then
      n = n - 1
    end
    return n
  end,
})

return fangyuan
