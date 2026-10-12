local qianlong = fk.CreateSkill {
  name = "mobile__qianlong",
  tags = { Skill.Permanent },
  related_skills = { "mobile_qianlong__qingzheng", "mobile_qianlong__jiushi", "mobile_qianlong__fangzhu", "juejin" },
}

Fk:loadTranslationTable{
  ["mobile__qianlong"] = "潜龙",
  [":mobile__qianlong"] = "持恒技，游戏开始时，你获得20点道心值；如下情况时，你获得对应数量的道心值：当你受到1点伤害后——" ..
  "10点；当你造成1点伤害后——15点；当你获得牌后——5点。<br>你根据道心值视为拥有以下技能：25点-〖清正〗；50点-〖酒诗〗；75点-〖放逐〗；" ..
  "99点-〖决进〗。你的道心值上限为99。",

  ["@mobile__qianlong_daoxin"] = "道心值",

  ["$mobile__qianlong1"] = "暗蓄忠君之士，以待破局之机！",
  ["$mobile__qianlong2"] = "若安司马于外，或则皇权可收！",
  ["$mobile__qianlong3"] = "朕为天子，岂忍威权日去！",
  ["$mobile__qianlong4"] = "假以时日，必讨司马一族！",
  ["$mobile__qianlong5"] = "权臣震主，竟视天子于无物！",
  ["$mobile__qianlong6"] = "朕行之决矣！正使死又何惧？",
}

qianlong:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  if player:getMark("@mobile__qianlong_daoxin") >= 25 and not player:hasSkill("mobile_qianlong__qingzheng") then
    room:handleAddLoseSkills(player, "mobile_qianlong__qingzheng")
  end
  if player:getMark("@mobile__qianlong_daoxin") >= 50 and not player:hasSkill("mobile_qianlong__jiushi") then
    room:handleAddLoseSkills(player, "mobile_qianlong__jiushi")
  end
  if player:getMark("@mobile__qianlong_daoxin") >= 75 and not player:hasSkill("mobile_qianlong__fangzhu") then
    room:handleAddLoseSkills(player, "mobile_qianlong__fangzhu")
  end
  if player:getMark("@mobile__qianlong_daoxin") >= 99 and not player:hasSkill("juejin") then
    room:handleAddLoseSkills(player, "juejin")
  end
end)

qianlong:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@mobile__qianlong_daoxin", 0)
  room:handleAddLoseSkills(player, "-mobile_qianlong__qingzheng|-mobile_qianlong__jiushi|-mobile_qianlong__fangzhu|-juejin")
end)

local function ChangeDaoxin(player, num)
  local room = player.room
  local daoxin = player:getMark("@mobile__qianlong_daoxin")
  num = math.min(99 - daoxin, num)
  if num > 0 then
    room:setPlayerMark(player, "@mobile__qianlong_daoxin", daoxin + num)
    if player:getMark("@mobile__qianlong_daoxin") >= 25 and not player:hasSkill("mobile_qianlong__qingzheng") then
      room:handleAddLoseSkills(player, "mobile_qianlong__qingzheng")
    end
    if player:getMark("@mobile__qianlong_daoxin") >= 50 and not player:hasSkill("mobile_qianlong__jiushi") then
      room:handleAddLoseSkills(player, "mobile_qianlong__jiushi")
    end
    if player:getMark("@mobile__qianlong_daoxin") >= 75 and not player:hasSkill("mobile_qianlong__fangzhu") then
      room:handleAddLoseSkills(player, "mobile_qianlong__fangzhu")
    end
    if player:getMark("@mobile__qianlong_daoxin") >= 99 and not player:hasSkill("juejin") then
      room:handleAddLoseSkills(player, "juejin")
    end
  end
end

qianlong:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(qianlong.name) and player:getMark("@mobile__qianlong_daoxin") < 99
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 20
    if player:hasSkill("weitong") and table.find(room.alive_players, function(p)
      return p ~= player and p.kingdom == "wei"
    end)
    then
      num = 60
      player:broadcastSkillInvoke("weitong")
      room:notifySkillInvoked(player, "weitong", "support")
    end
    ChangeDaoxin(player, num)
  end,
})
qianlong:addEffect(fk.Damaged, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qianlong.name) and player:getMark("@mobile__qianlong_daoxin") < 99
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ChangeDaoxin(player, 10 * data.damage)
  end,
})
qianlong:addEffect(fk.Damage, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qianlong.name) and player:getMark("@mobile__qianlong_daoxin") < 99
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ChangeDaoxin(player, 15 * data.damage)
  end,
})
qianlong:addEffect(fk.AfterCardsMove, {
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(qianlong.name) and player:getMark("@mobile__qianlong_daoxin") < 99 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ChangeDaoxin(player, 5)
  end,
})

return qianlong
