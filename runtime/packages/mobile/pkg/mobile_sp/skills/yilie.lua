local yilie = fk.CreateSkill{
  name = "mobile__yilie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__yilie"] = "义烈",
  [":mobile__yilie"] = "锁定技，游戏开始时，你选择一名其他角色。<br>当该角色受到伤害时，若你没有“烈”标记，则你获得等同于伤害值数量的“烈”标记，" ..
  "然后防止此伤害；<br>当该角色对其他角色造成伤害后，你回复1点体力；<br>结束阶段，若你有“烈”标记，你摸一张牌并失去X点体力（X为你的“烈”标记数），" ..
  "然后移去你的所有“烈”标记。",

  ["@@mobile__yilie"] = "义烈",
  ["@mobile__yilie_lie"] = "烈",
  ["#mobile__yilie-choose"] = "义烈：请选择一名其他角色，你为其抵挡伤害，且其造成伤害后你回复体力",

  ["$mobile__yilie1"] = "禽兽尚且知义，而况于人乎？",
  ["$mobile__yilie2"] = "班虽无名，亦有忠义在骨！",
  ["$mobile__yilie3"] = "身不慕生，宁比泰山之重！",
}

yilie:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yilie.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = yilie.name,
      prompt = "#mobile__yilie-choose",
      cancelable = false,
    })[1]
    room:addTableMark(to, "@@mobile__yilie", player.id)
  end,
})

yilie:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yilie.name) and table.contains(target:getTableMark("@@mobile__yilie"), player.id) and
      player:getMark("@mobile__yilie_lie") == 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@mobile__yilie_lie", data.damage)
    data:preventDamage()
  end,
})

yilie:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yilie.name) and target and
      table.contains(target:getTableMark("@@mobile__yilie"), player.id) and
      data.to ~= player and player:isWounded()
  end,
  on_use = function (self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = yilie.name,
    }
  end,
})

yilie:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yilie.name) and player.phase == Player.Finish and
      player:getMark("@mobile__yilie_lie") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1, yilie.name)
    if not player.dead then
      room:loseHp(player, player:getMark("@mobile__yilie_lie"), yilie.name)
      if not player.dead then
        room:setPlayerMark(player, "@mobile__yilie_lie", 0)
      end
    end
  end,
})

yilie:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@mobile__yilie", player.id)
  end
end)

return yilie
