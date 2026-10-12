local osShanli = fk.CreateSkill {
  name = "os__shanli",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["os__shanli"] = "擅立",
  [":os__shanli"] = "觉醒技，准备阶段，若你对至少两名角色发动过〖景略〗，并且〖败移〗已发动，" ..
  "你减1点体力上限并选择一名角色，你从随机三个主公技中选择一个令其获得。",

  ["#os__shanli-ask"] = "擅立：选择一名角色，令其获得一个主公技",
  ["#os__shanli-skill"] = "擅立：选择一个主公技令 %src 获得",

  ["$os__shanli1"] = "荡尘涤污，重整河山，便在今日！",
  ["$os__shanli2"] = "效伊尹霍光，以返天下清明。",
}

osShanli:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osShanli.name) and
      player:usedSkillTimes(osShanli.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getTableMark("_os__jinglue") > 1 and
      player:usedSkillTimes("os__baiyi", Player.HistoryGame) > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShanli.name
    local room = player.room
    room:changeMaxHp(player, -1)
    local to = room:askToChoosePlayers(
      player,
      {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__shanli-ask",
        skill_name = skillName,
        cancelable = false,
      }
    )[1]

    local skills = {}
    for _, general in ipairs(Fk:getAllGenerals()) do
      for _, skName in ipairs(general:getSkillNameList(true)) do
        local skill = Fk.skills[skName]
        if skill and skill:hasTag(Skill.Lord) then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end

    if #skills > 0 then
      skills = room:tableRandomPick(skills, 3)
      local choice = room:askToChoice(
        player,
        {
          choices = skills,
          skill_name = skillName,
          prompt = "#os__shanli-skill:" .. to.id,
          detailed = true,
        }
      )

      room:handleAddLoseSkills(to, choice)
    end
  end,
})

return osShanli
