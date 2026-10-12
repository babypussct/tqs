local zhaohan = fk.CreateSkill {
  name = "zhaohan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhaohan"] = "昭汉",
  [":zhaohan"] = "锁定技，准备阶段，若X：小于4，你加1点体力上限并回复1点体力；不小于4且小于7，你减1点体力上限（X为你发动过本技能的次数）。",

  ["$zhaohan1"] = "天道昭昭，再兴如光武亦可期。",
  ["$zhaohan2"] = "汉祚将终，我又岂能无憾。",
}

zhaohan:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(zhaohan.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(zhaohan.name, Player.HistoryGame) < 7
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhaohan.name
    local room = player.room
    if player:usedSkillTimes(skillName, Player.HistoryGame) < 5 then
      player:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(player, skillName, "support")
      room:changeMaxHp(player, 1)
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    else
      player:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(player, skillName, "negative")
      room:changeMaxHp(player, -1)
    end
  end,
})

return zhaohan
