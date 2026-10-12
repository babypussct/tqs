local dili = fk.CreateSkill{
  name = "dili",
  tags = { Skill.Wake },
  related_skills = { "shengzhi", "quandao", "chigang", "qionglan", "jiaohui", "yuanlv" },
}

Fk:loadTranslationTable{
  ["dili"] = "帝力",
  [":dili"] = "觉醒技，当你的技能数超过体力上限后，你减少1点体力上限，失去任意个其他技能并获得〖圣质〗〖权道〗〖持纲〗中的前等量个。",

  ["#dili-invoke"] = "帝力：选择失去至多三个技能",
  [":Cancel"] = "取消",

  ["$dili1"] = "身处巅峰，览天下大事。",
  ["$dili2"] = "位居至尊，掌至高之权。",
}

local spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dili.name) and
      player:usedSkillTimes(dili.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(
      player:getSkillNameList(),
      function(skill)
        return Fk.skills[skill] and Fk.skills[skill]:isPlayerSkill(player)
      end
    ) > player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room---@type Room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local skills = player:getSkillNameList()
    skills = table.filter(skills, function(skill) return Fk.skills[skill] and Fk.skills[skill]:isPlayerSkill(player) end)
    table.removeOne(skills, dili.name)
    local choice = room:askToChoices(player, {
      min_num = 0, max_num = 3, cancelable = false, prompt = "#dili-invoke", choices = skills, detailed = true,
    })
    if #choice > 0 then
      room:handleAddLoseSkills(player, "-"..table.concat(choice, "|-"))
      skills = {"shengzhi", "quandao", "chigang"}
      local skill = {}
      for i = 1, #choice, 1 do
        if i > 3 then break end
        table.insert(skill, skills[i])
      end
      room:handleAddLoseSkills(player, table.concat(skill, "|"))
    end
  end,
}

dili:addEffect(fk.EventAcquireSkill, spec)
dili:addEffect(fk.MaxHpChanged, spec)

return dili
