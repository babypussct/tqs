local osBaijia = fk.CreateSkill {
  name = "os__baijia",
  tags = { Skill.Limited },
  related_skills = { "os__canshi" },
}

Fk:loadTranslationTable{
  ["os__baijia"] = "拜假",
  [":os__baijia"] = "限定技，准备阶段，你可以加1点体力上限，回复1点体力，获得〖蚕食〗，"..
  "然后若你因〖骨疽〗获得的牌数小于存活角色数或有没有“傀”的其他角色，你令所有没有“傀”的其他角色各获得1枚“傀”，失去〖骨疽〗。",

  ["$os__baijia1"] = "没有人能阻止我的觉醒。",
  ["$os__baijia2"] = "哼哼哼……这才是我的真面目。",
}

osBaijia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osBaijia.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(osBaijia.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = osBaijia.name,
    }
    room:handleAddLoseSkills(player, "os__canshi")
    local players = table.filter(room.alive_players, function(p)
      return p ~= player and p:getMark("@@os__puppet") == 0
    end)
    if #players > 0 or player:getMark("os__guju") < #room.alive_players then
      for _, p in ipairs(players) do
        room:setPlayerMark(p, "@@os__puppet", 1)
      end
      room:handleAddLoseSkills(player, "-os__guju")
    else
      room:setPlayerMark(player, "@os__guju", 0)
    end
  end,
})

return osBaijia
