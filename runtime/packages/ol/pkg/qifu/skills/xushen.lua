local xushen = fk.CreateSkill{
  name = "ol__xushen",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ol__xushen"] = "许身",
  [":ol__xushen"] = "限定技，当你进入濒死状态时，你可令一名其他角色选择一项：1.其失去所有技能获得〖征南〗：2.其获得〖镇南〗。",

  ["#ol__xushen-choose"] = "许身：你可以令一名其他角色选择失去所有技能获得〖征南〗或获得〖镇南〗",
  ["#ol__xushen-chooseskill"] = "许身：选择失去所有技能获得〖征南〗：或获得〖镇南〗",

  ["$ol__xushen1"] = "救命之恩，涌泉相报。",
  ["$ol__xushen2"] = "解我危难，报君华彩。",
}

xushen:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xushen.name) and player:usedSkillTimes(xushen.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xushen.name,
      prompt = "#ol__xushen-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = room:askToChoice(to, {
      choices = {"ol__zhengnan", "ol__zhennan"},
      skill_name = xushen.name,
      detailed = true,
      prompt = "#ol__xushen-chooseskill",
    })
    if choice == "ol__zhengnan" then
      local skills = {}
      for _, s in ipairs(to.player_skills) do
        if s:isPlayerSkill(to) then
          table.insertIfNeed(skills, s.name)
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"))
      end
      room:handleAddLoseSkills(to, "ol__zhengnan")
    else
      room:handleAddLoseSkills(to, "ol__zhennan")
    end
  end,
})

return xushen
