
local baijia = fk.CreateSkill {
  name = "baijia",
  tags = { Skill.Wake },
  related_skills = { "canshih" },
}

Fk:loadTranslationTable{
  ["baijia"] = "拜假",
  [":baijia"] = "觉醒技，准备阶段，若你因〖骨疽〗获得的牌数大于等于7，你增加1点体力上限并回复1点体力，" ..
  "然后令所有没有“傀”的其他角色获得“傀”，最后你失去〖骨疽〗，获得〖蚕食〗。",

  ["$baijia1"] = "以邪马台的名义。",
  ["$baijia2"] = "我要摧毁你的一切，然后建立我的国度。",
}

baijia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baijia.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(baijia.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player:getMark("@guju") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = baijia.name,
    }
    if player.dead then return end
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p:getMark("@@puppet") == 0 then
        room:setPlayerMark(p, "@@puppet", 1)
      end
    end
    room:handleAddLoseSkills(player, "-guju|canshih")
  end,
})

return baijia
