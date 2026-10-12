local baiyin = fk.CreateSkill {
  name = "mobile__baiyin",
  tags = { Skill.Wake },
  related_skills = { "mobile__jilue" },
}

Fk:loadTranslationTable{
  ["mobile__baiyin"] = "拜印",
  [":mobile__baiyin"] = "觉醒技，准备阶段，若你的“忍”标记数不少于4，你减1点体力上限，然后获得〖极略〗。",

  ["$mobile__baiyin1"] = "乱世已尽，老夫当再开万世河山！",
  ["$mobile__baiyin2"] = "明出地上，自昭天德，此为晋也！",
}

baiyin:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baiyin.name) and
      player.phase == Player.Start and player:usedSkillTimes(baiyin.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player:getMark("@mobile__renjie_ren") > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "mobile__jilue")
  end,
})

return baiyin
