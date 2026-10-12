local zhaoxiong = fk.CreateSkill {
  name = "mobile__zhaoxiong",
  tags = { Skill.Permanent, Skill.Limited },
  dynamic_desc = function (self, player, lang)
    if Fk:currentRoom():isGameMode("role_mode") then
      return "mobile__zhaoxiong_role_mode"
    else
      return "mobile__zhaoxiong_1v2"
    end
  end,
}

Fk:loadTranslationTable{
  ["mobile__zhaoxiong"] = "昭凶",
  [":mobile__zhaoxiong"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗"..
  "（若为身份模式，则删去〖挟征〗中的“优先指定同势力角色为目标”）。",

  [":mobile__zhaoxiong_role_mode"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗，"..
  "并删去〖挟征〗中的“优先指定同势力角色为目标”。",
  [":mobile__zhaoxiong_1v2"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗。",

  ["#mobile__zhaoxiong-invoke"] = "昭凶：是否变为群势力、失去“谦吞”、获得“威肆”和“荡异”？",

  ["$mobile__zhaoxiong1"] = "天下名为曹姓，实归吾司马一族！",
  ["$mobile__zhaoxiong2"] = "陛下有罪，吾当治之以对天下！",
}

zhaoxiong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaoxiong.name) and player.phase == Player.Start and
      player:usedSkillTimes(zhaoxiong.name, Player.HistoryGame) == 0 and
      player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhaoxiong.name,
      prompt = "#mobile__zhaoxiong-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "mobile__xiezheng_update", 1)
    if player.general == "mobile__simazhao" then
      room:setPlayerProperty(player, "general", "mobile2__simazhao")
    elseif player.deputyGeneral == "mobile__simazhao" then
      room:setPlayerProperty(player, "deputyGeneral", "mobile2__simazhao")
    end
    if player.kingdom ~= "qun" then
      room:changeKingdom(player, "qun", true)
    end
    room:handleAddLoseSkills(player, "-mobile__qiantun|mobile__weisi|mobile__dangyi")
  end,
})

zhaoxiong:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return zhaoxiong
