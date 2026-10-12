local fuzhan = fk.CreateSkill {
  name = "fuzhan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fuzhan"] = "复盏",
  [":fuzhan"] = "限定技，当一名角色脱离濒死状态时，你可以回复体力至体力上限，修改〖绝谋〗（增加时机“回合开始时或结束时”）。",

  ["$fuzhan1"] = "丞相！五丈原的那盏灯，没有灭！",
  ["$fuzhan2"] = "汉贼不两立，王业不偏安！",
}

fuzhan:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player, data)
    return target:isAlive() and player:hasSkill(fuzhan.name) and player:usedSkillTimes(fuzhan.name, Player.HistoryGame) == 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = player.maxHp - player.hp,
      recoverBy = player,
      skillName = fuzhan.name,
    }

    room:setPlayerMark(player, "juemou_upgrade", 1)
  end
})

fuzhan:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return fuzhan
