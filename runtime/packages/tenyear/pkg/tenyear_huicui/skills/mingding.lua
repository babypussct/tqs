local mingding = fk.CreateSkill {
  name = "mingding",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["mingding"] = "命定",
  [":mingding"] = "限定技，当你进入濒死状态时，你可以失去除〖命定〗外的所有技能并将体力值回复至1点，"..
    "若如此做，你摸〖相谶〗获得过的技能数张牌（至多五张）并随机获得其中三个技能，" ..
    "然后直到你的下个回合结束，防止你受到的伤害，你的下个回合的回合结束时，你失去所有体力。",

  ["@@mingding"] = "命定",

  ["$mingding1"] = "举镜视面，自知刑死，唯叹造化弄人。",
  ["$mingding2"] = "阻门之芳兰，敬待潞涿君鉏之。",
}

mingding:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingding.name) and
        player.hp < 1 and player:usedSkillTimes(mingding.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --回合内发动会持续到下个回合，用一个标记来辅助判断
    room:setPlayerMark(player, "mingding-turn", 1)
    room:setPlayerMark(player, "@@mingding", 1)
    local skills = player:getSkillNameList()
    table.removeOne(skills, mingding.name)
    local changeSkills=table.simpleClone(skills)
    for _, skillName in ipairs(skills) do
      if Fk.skill_skels[skillName] and Fk.skill_skels[skillName].mode_skill then
        table.removeOne(changeSkills, skillName)
      end
    end
    if #changeSkills > 0 then
      room:handleAddLoseSkills(player, "-" .. table.concat(changeSkills, "|-"))
    end
    room:recover {
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = mingding.name,
    }
    if player.dead then return end
    if player:getMark("all_xiangchen_skills") ~= 0 then
      local all_skills = player:getTableMark("all_xiangchen_skills")
      player:drawCards(math.min(#all_skills, 5), mingding.name)
      if player.dead then return end
      room:handleAddLoseSkills(player, room:tableRandomPick(all_skills, 3))
    end
  end,
})

mingding:addEffect(fk.DetermineDamageInflicted, {
  is_delay_effect = true,
  anim_type = "defensive",
  audio_index = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingding.name) and player:getMark("@@mingding") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

mingding:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  anim_type = "negative",
  audio_index = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingding.name) and
      player:getMark("@@mingding") > 0 and player:getMark("mingding-turn") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@mingding", 0)
    if player.hp > 0 then
      room:loseHp(player, player.hp, mingding.name, player)
    end
  end,
})

mingding:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@mingding", 0)
  player.room:setPlayerMark(player, "mingding-turn", 0)
end)

return mingding
