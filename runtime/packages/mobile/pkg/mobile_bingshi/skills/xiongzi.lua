local xiongzi = fk.CreateSkill {
  name = "xiongzi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiongzi"] = "雄姿",
  [":xiongzi"] = "限定技，准备阶段，你可以令本局游戏你的〖炽沄〗、〖焰洄〗和〖焚涛〗只能在你的回合内发动，" ..
  "仅保留其中全部的一选项或二选项，并摸两张牌。",

  ["#xiongzi-invoke"] = "雄姿：你可令你其他技能均只能在回合内发动指定选项，然后摸2张牌",
  ["xiongzi_2"] = "选项一",
  ["xiongzi_1"] = "选项二",
  ["@xiongzi-noclear"] = "雄姿",

  ["$xiongzi1"] = "纵有波汹浪涌，岂阻江海奔流？",
  ["$xiongzi2"] = "雄图尽展，坐待天下归吴。",
  ["$xiongzi3"] = "以吾一人薪火，焚没百万庸贼。",
  ["$xiongzi4"] = "九州犹在，试问谁主沉浮？",
}

xiongzi:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Start and
      player:hasSkill(xiongzi.name) and
      player:usedSkillTimes(xiongzi.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askToChoice(
      player,
      {
        choices = { "xiongzi_2", "xiongzi_1" },
        skill_name = xiongzi.name,
        cancelable = true,
        prompt = "#xiongzi-invoke",
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local choice = event:getCostData(self).choice
    local room = player.room

    if player.general == "m_shi__zhouyu" then
      player.general = "m_shi2__zhouyu"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "m_shi__zhouyu" then
      player.deputyGeneral = "m_shi2__zhouyu"
      room:broadcastProperty(player, "deputyGeneral")
    end

    room:setPlayerMark(player, "@xiongzi-noclear", choice)
    player:drawCards(2, xiongzi.name)
  end,
})

return xiongzi
