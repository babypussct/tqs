
local fenxin = fk.CreateSkill {
  name = "mobile__fenxin",
}

Fk:loadTranslationTable {
  ["mobile__fenxin"] = "焚心",
  [":mobile__fenxin"] = "被你杀死的角色亮出其身份牌前，你可以选择一项：<br>"..
  "1.若其与你阵营不同，获得其武将牌上的所有技能（限定技、觉醒技、使命技、主公技、持恒技除外）；<br>"..
  "2.与其交换身份牌（你与其身份牌均非明置时方可选择）。",

  ["#mobile__fenxin-invoke"] = "焚心：你可以对 %dest 发动“焚心”，选择一项",
  ["mobile__fenxin_skill"] = "获得技能",
  ["mobile__fenxin_role"] = "交换身份",

  ["$mobile__fenxin1"] = "你，该献出自己最后的价值了！",
  ["$mobile__fenxin2"] = "能够为我所用，你应该感到庆幸。",
}

fenxin:addEffect(fk.BeforeGameOverJudge, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.killer == player and player:hasSkill(fenxin.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if not player:isFriend(target) then
      table.insert(choices, "mobile__fenxin_skill")
    end
    if not player.role_shown and not target.role_shown then
      table.insert(choices, "mobile__fenxin_role")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fenxin.name,
      all_choices = { "mobile__fenxin_skill", "mobile__fenxin_role" },
      prompt = "#mobile__fenxin-invoke::"..target.id,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { target }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "mobile__fenxin_skill" then
      local skills = Fk.generals[target.general]:getSkillNameList()
      if target.deputyGeneral ~= "" then
        table.insertTableIfNeed(skills, Fk.generals[target.deputyGeneral]:getSkillNameList())
      end
      skills = table.filter(skills, function (s)
        return not table.find({ Skill.Limited, Skill.Wake, Skill.Quest, Skill.Permanent }, function (tag)
          return Fk.skills[s]:hasTag(tag)
        end)
      end)
      if #skills > 0 then
        room:handleAddLoseSkills(player, skills)
      end
    else
      local playerRole, targetRole = target.role, player.role
      room:changeRole(player, playerRole)
      room:changeRole(target, targetRole)
    end
  end,
})

return fenxin
