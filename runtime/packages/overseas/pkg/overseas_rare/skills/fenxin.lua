local fenxin = fk.CreateSkill{
  name = "os__fenxin",
  tags = { Skill.Quest },
}

Fk:loadTranslationTable{
  ["os__fenxin"] = "焚心",
  [":os__fenxin"] = "使命技，游戏开始时，你选择一名其他角色，你与其互相计算距离视为1。当你或其受到伤害后，你摸一张牌。<br>" ..
      "⬤　成功：当你与其累计受到4点伤害或其死亡后，你将〖竭缘〗中的“弃置一张黑/红色手牌”修改为“重铸一张牌”。<br>" ..
      "⬤　失败：你成功达成使命前，进入濒死状态时，你将体力回复至1点。",

  ["#os__fenxin-ask"] = "焚心：选择一名其他角色，你与其互相计算距离视为1，当你或其受到伤害后，你摸一张牌",

  ["@os__fenxin"] = "焚心",
  ["@os__fenxin_to"] = "被焚心",

  ["$os__fenxin1"] = "",
  ["$os__fenxin2"] = "",
}

fenxin:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fenxin.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      skill_name = fenxin.name,
      cancelable = false,
      prompt = "#os__fenxin-ask",
    })
    event:setCostData(self, {tos = to})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, "os__fenxin_target", {to, 0})
    room:setPlayerMark(to, "@os__fenxin_to", player)
  end,
})

local function checkFenxin(from, to, bi)
  return (from:hasSkill(fenxin.name) and from:getMark("os__fenxin_target") ~= 0 and from:getMark("os__fenxin_target")[1] == to)
    or (bi and to:hasSkill(fenxin.name) and to:getMark("os__fenxin_target") ~= 0 and to:getMark("os__fenxin_target")[1] == from)
end

fenxin:addEffect("distance", {
  fixed_func = function (self, from, to, card)
    if checkFenxin(from, to, true) then
      return 1
    end
  end
})

local function clearFenxinMark(room, player)
  room:setPlayerMark(player, "@os__fenxin", 0)
  if player:getMark("os__fenxin_target") ~= 0 then
    local to = player:getMark("os__fenxin_target")[1]
    room:setPlayerMark(to, "@os__fenxin_to", 0)
    room:setPlayerMark(player, "os__fenxin_target", 0)
  end
end

---@param player ServerPlayer
local function fenxinSuccess(player)
  local room = player.room
  room:setPlayerMark(player, "os__jieyuan_updated", 1)
  room:updateQuestSkillState(player, fenxin.name)
  room:invalidateSkill(player, fenxin.name)
  clearFenxinMark(room, player)
end

fenxin:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(fenxin.name) and (target == player or checkFenxin(player, target))
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, fenxin.name)
    if player.dead then return end
    local room = player.room
    local record = player:getMark("os__fenxin_target")[2] + data.damage
    if record >= 4 then
      fenxinSuccess(player)
    else
      room:setPlayerMark(player, "@os__fenxin", record)
      room:setPlayerMark(player, "os__fenxin_target", {player:getMark("os__fenxin_target")[1], record})
    end
  end
})

fenxin:addEffect(fk.Deathed, {
  can_trigger = function (self, event, target, player, data)
    return checkFenxin(player, target)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    fenxinSuccess(player)
  end,
})

fenxin:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(fenxin.name) and player:getMark("os__fenxin_target") ~= 0 and player.hp < 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:updateQuestSkillState(player, fenxin.name, true)
    room:invalidateSkill(player, fenxin.name)
    clearFenxinMark(room, player)
    if player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = fenxin.name,
      }
    end
  end,
})

fenxin:addLoseEffect(function (self, player, is_death)
  clearFenxinMark(player.room, player)
end)

return fenxin
