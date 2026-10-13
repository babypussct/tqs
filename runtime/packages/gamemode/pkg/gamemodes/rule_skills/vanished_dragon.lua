local rule = fk.CreateSkill {
  name = "#vanished_dragon_rule&",
}

Fk:loadTranslationTable{
  ["#VDLordExploded"] = "明忠阵亡，主公暴露：%from",
}

--明忠阵亡时主公暴露并获得主公技
rule:addEffect(fk.BuryVictim, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.rest == 0 and player.id == player.room:getBanner("ShownLoyalist")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local lord = room:getLord()
    if not lord then return end
    room:setPlayerProperty(lord, "role_shown", true)
    room:sendLog{
      type = "#VDLordExploded",
      from = lord.id,
      toast = true,
    }

    local skills = Fk.generals[lord.general]:getSkillNameList(true)
    local deputy = Fk.generals[lord.deputyGeneral]
    if deputy then
      table.insertTableIfNeed(skills, deputy:getSkillNameList(true))
    end
    for _, sname in ipairs(skills) do
      if Fk.skills[sname]:hasTag(Skill.Lord) then
        room:handleAddLoseSkills(lord, sname, nil, false)
      end
    end
  end,
})

return rule
