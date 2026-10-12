local moubian = fk.CreateSkill{
  name = "moubian",
  related_skills = { "zhouxi" },
}

Fk:loadTranslationTable{
  ["moubian"] = "谋变",
  [":moubian"] = "准备阶段，若你的“诡伏”记录不小于3，你可以<a href='#RuMoDesc'><font color='red'>入魔</font></a>，获得记录的技能，然后获得技能〖骤袭〗。",

  ["$moubian1"] = "别跟我谈什么对错！我的灵魂，即是我的正义！",
  ["$moubian2"] = "我这把剑，该见见血了！",
  ["$moubian3"] = "无天无界，我就是天命！",
  ["$moubian4"] = "自今日起，我剑由我不由人！",
}

moubian:addEffect(fk.EventPhaseStart, {
  anim_type = "big",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(moubian.name) and player.phase == Player.Start and
      not player:hasSkill("#rumo", true) and
      (#player:getTableMark("guifu_card_record") + #player:getTableMark("guifu_skill_record")) > 2
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = player:getTableMark("guifu_skill_record")
    table.insert(skills, "zhouxi")
    room:handleAddLoseSkills(player, "#rumo", nil, false, true)
    room:handleAddLoseSkills(player, table.concat(skills, "|"))
  end,
})

moubian:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return moubian
