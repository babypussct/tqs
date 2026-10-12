local shenpei = fk.CreateSkill{
  name = "shenpeij",
  tags = { Skill.Limited },
  related_skills = { "huitian" },
}

Fk:loadTranslationTable{
  ["shenpeij"] = "神霈",
  [":shenpeij"] = "限定技，你进入濒死时，可回复X点体力（X为你本局游戏进入过濒死的次数），"..
    "对一名角色造成等量雷电伤害并获得〖回天〗。",

  ["#shenpeij-invoke"]= "神霈：你可以回复%arg点体力并获得“回天”",
  ["#shenpeij-choose"]= "神霈：对一名其他角色造成%arg点雷电伤害",

  ["$shenpeij1"] = "雄山峻壑终踏过，须信寒过总是春。",
  ["$shenpeij2"] = "世有云霓之望，维必借天馈之！",
}

shenpei:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.hp < 1 and player:hasSkill(shenpei.name) and
      player:usedSkillTimes(shenpei.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
      if e.data.who == player then
        x = x + 1
      end
    end, Player.HistoryGame)
    return room:askToSkillInvoke(player, {skill_name = shenpei.name, prompt = "#shenpeij-invoke:::" .. x,})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
      if e.data.who == player then
        x = x + 1
      end
    end, Player.HistoryGame)
    room:recover {
      who = player,
      num = x,
      recoverBy = player,
      skillName = shenpei.name
    }
    if player.dead then return end
    room:handleAddLoseSkills(player, "huitian")
    if player.dead then return end
    local others = room:getOtherPlayers(player, false)
    if #others == 0 then return end
    room:damage {
      from = player,
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = others,
        skill_name = shenpei.name,
        prompt = "#shenpeij-choose:::" .. x,
        cancelable = false,
      })[1],
      damage = x,
      damageType = fk.ThunderDamage,
      skillName = shenpei.name
    }
  end,
})

return shenpei
