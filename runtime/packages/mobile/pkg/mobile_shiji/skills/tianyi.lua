local tianyi = fk.CreateSkill {
  name = "mobile__tianyi",
  tags = { Skill.Wake },
  related_skills = { "zuoxing" },
}

Fk:loadTranslationTable{
  ["mobile__tianyi"] = "天翊",
  [":mobile__tianyi"] = "觉醒技，准备阶段，若所有存活角色本局游戏均受到过伤害，你加2点体力上限，回复1点体力，令一名角色获得技能〖佐幸〗。",

  ["#mobile__tianyi-choose"] = "天翊：令一名角色获得技能“佐幸”",

  ["$mobile__tianyi1"] = "天命靡常，惟德是辅。",
  ["$mobile__tianyi2"] = "可成吾志者，必此人也！",
}

tianyi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianyi.name) and player.phase == Player.Start and
      player:usedSkillTimes(tianyi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room.alive_players, function(p)
      return #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == p
      end, Player.HistoryGame) > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 2)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tianyi.name,
      }
      if player.dead then return end
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = tianyi.name,
      prompt = "#mobile__tianyi-choose",
      cancelable = false,
    })[1]
    room:addTableMark(to, "mobile__tianyi_src", player.id)
    room:handleAddLoseSkills(to, "zuoxing")
  end,
})

tianyi:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic.benefit = ai:needHelp(p)
      end,
    })
  end,
})

return tianyi
