local processMark = function (value)
  if value == 0 then return 1 end
  return tonumber(value)
end

local junsi = fk.CreateSkill{
  name = "os__junsi",
  tags = {Skill.Compulsory},
  dynamic_desc = function (self, player, lang)
    local ret = table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p:hasSkill(self.name, true) end)
      and "os__junsi_inner:" or "os__junsi_only:" -- : for {1}
    return ret .. processMark(player:getMark("@os__junsi0")) .. ":" .. processMark(player:getMark("@os__junsi1"))
  end,
}

Fk:loadTranslationTable{
  ["os__junsi"] = "隽嗣",
  [":os__junsi"] = "锁定技，每回合各限两次，当你对有〖隽嗣〗的角色造成伤害后，你摸一张牌；"..
    "当你受到有〖隽嗣〗的角色造成的伤害后，你弃置一张牌。"..
    "若场上仅你有〖隽嗣〗，此技能描述中的“有〖隽嗣〗的角色”改为“一名角色”。",

  [":os__junsi_inner"] = "锁定技，每回合各限两次，当你对有〖隽嗣〗的角色造成伤害后，你摸{1}张牌；"..
    "当你受到有〖隽嗣〗的角色造成的伤害后，你弃置{2}张牌。"..
    "若场上仅你有〖隽嗣〗，此技能描述中的“有〖隽嗣〗的角色”改为“一名角色”。",
  [":os__junsi_only"] = "锁定技，每回合各限两次，当你对一名角色造成伤害后，你摸{1}张牌；"..
    "当你受到一名角色造成的伤害后，你弃置{2}张牌。"..
    "<font color = 'gray'>若场上有其他角色有〖隽嗣〗，此技能描述中的“一名角色”改为“有〖隽嗣〗的角色”。</font>",

  ["@os__junsi0"] = "隽嗣 摸",
  ["@os__junsi1"] = "隽嗣 弃",
  ["#os__junsi-discard"] = "隽嗣：%src对你造成伤害，请弃置%arg张牌",

  ["$os__junsi1"] = "鞭笞天下，方可昭吾之威德！",
  ["$os__junsi2"] = "僭越之徒，何敢妄加染指！",
  ["$os__junsi3"] = "呃啊，手足之患不除，吾心病难医！",
  ["$os__junsi4"] = "既然如此，休怪为兄无情！",
}

junsi:addEffect(fk.Damage, {
  mute = true,
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
      player:usedEffectTimes(self.name) < 2 and
      (data.to:hasSkill(self.name, true) or table.every(player.room:getOtherPlayers(player), function(p)
        return not p:hasSkill(self.name, true)
      end)) and processMark(player:getMark("@os__junsi0")) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "drawcard")
    player:broadcastSkillInvoke(junsi.name, math.random(1, 2))
    player:drawCards(processMark(player:getMark("@os__junsi0")), self.name)
  end
})

junsi:addEffect(fk.Damaged, {
  mute = true,
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
      player:usedEffectTimes(self.name) < 2 and data.from and
      (data.from:hasSkill(self.name, true) or table.every(player.room:getOtherPlayers(player), function(p)
        return not p:hasSkill(self.name, true)
      end)) and processMark(player:getMark("@os__junsi1")) > 0 and not player:isNude()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "negative")
    player:broadcastSkillInvoke(junsi.name, math.random(3, 4))
    local num = processMark(player:getMark("@os__junsi1"))
    room:askToDiscard(player, {
      min_num = num,
      max_num = num,
      skill_name = self.name,
      include_equip = true,
      prompt = "#os__junsi-discard:" .. data.from.id .. "::" .. num,
      cancelable = false,
    })
  end
})

return junsi
