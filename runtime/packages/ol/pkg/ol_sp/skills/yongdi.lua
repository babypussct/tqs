local yongdi = fk.CreateSkill {
  name = "ol__yongdi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ol__yongdi"] = "拥嫡",
  [":ol__yongdi"] = "限定技，回合开始时，你可以令一名其他男性角色增加1点体力上限并回复1点体力，然后其获得武将牌上的主公技。",

  ["#ol__yongdi-choose"] = "拥嫡：令一名男性角色加1点体力上限、回复1点体力并获得其武将牌上的主公技",

  ["$ol__yongdi1"] = "臣愿为世子，肝脑涂地。",
  ["$ol__yongdi2"] = "嫡庶有别，尊卑有序。",
}

yongdi:addEffect(fk.TurnStart, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(yongdi.name) and
      player:usedSkillTimes(yongdi.name, Player.HistoryGame) == 0 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:isMale()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:isMale()
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = yongdi.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ol__yongdi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:changeMaxHp(to, 1)
    if to.dead then return end
    room:recover{
      who = to,
      num = 1,
      recoverBy = player,
      skillName = yongdi.name,
    }
    if to.dead then return end
    for _, s in ipairs(Fk.generals[to.general]:getSkillNameList(true)) do
      if Fk.skills[s]:hasTag(Skill.Lord) then
        room:handleAddLoseSkills(to, s)
      end
    end
    if to.deputyGeneral ~= "" then
      for _, s in ipairs(Fk.generals[to.deputyGeneral]:getSkillNameList(true)) do
        if Fk.skills[s]:hasTag(Skill.Lord) then
          room:handleAddLoseSkills(to, s)
        end
      end
    end
  end,
})

return yongdi
