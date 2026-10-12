local jimie = fk.CreateSkill {
  name = "jimie",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jimie"] = "寂灭",
  [":jimie"] = "限定技，出牌阶段结束时，你可以失去8个“霆”，对一名角色造成等于其体力上限的伤害。然后你〖驭雳〗的两项均执行后，此技能可再次发动。",

  ["#jimie-choose"] = "寂灭：失去8个“霆”，对一名角色造成其体力上限的伤害！",

  ["$jimie1"] = "赐万物寂然，赐万界终灭！",
  ["$jimie2"] = "万物重归于寂，天地唯领我名！",
  ["$jimie3"] = "我乃万法之法，戮神之神！",
  ["$jimie4"] = "此世终末之时，我将再度照临！",
}

jimie:addEffect(fk.EventPhaseEnd, {
  audio_index = { 1, 2 },
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(jimie.name) and player.phase == Player.Play and
      player:usedSkillTimes(jimie.name, Player.HistoryGame) == 0 and
      player:getMark("@machao_thunder") > 7
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#jimie-choose",
      skill_name = jimie.name,
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
    room:removePlayerMark(player, "@machao_thunder", 8)
    room:damage{
      from = player,
      to = to,
      damage = to.maxHp,
      skillName = jimie.name,
    }
    if not player.dead then
      room:setPlayerMark(player, jimie.name, { 1, 2 })
    end
  end,
})

jimie:addEffect(fk.AfterSkillEffect, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(jimie.name) ~= 0 and
      (data.skill.name == "yuli" or data.skill.name == "#yuli_2_trig")
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.skill.name == "yuli" then
      room:removeTableMark(player, jimie.name, 1)
    end
    if data.skill.name == "#yuli_2_trig" then
      room:removeTableMark(player, jimie.name, 2)
    end
    if player:getMark(jimie.name) == 0 then
      player:broadcastSkillInvoke(jimie.name, math.random(3, 4))
      player:setSkillUseHistory(jimie.name, 0, Player.HistoryGame)
    end
  end,
})

return jimie
