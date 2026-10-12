
local jieying = fk.CreateSkill {
  name = "ty__jieying",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__jieying"] = "结营",
  [":ty__jieying"] = "锁定技，你始终处于横置状态；已横置的角色手牌上限+2；结束阶段，你横置一名其他角色，然后令任意名已横置的角色各摸一张牌。",

  ["#ty__jieying-choose"] = "结营：选择一名其他角色，令其横置",
  ["#ty__jieying-draw"] = "结营：令任意名已横置的角色各摸一张牌",

  ["$ty__jieying1"] = "结桃园之义，雪手足之仇！",
  ["$ty__jieying2"] = "吾弟且慢行，待为兄报仇雪恨！",
}

jieying:addEffect(fk.GameStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jieying.name) and not player.chained
  end,
  on_use = function (self, event, target, player, data)
    player:setChainState(true)
  end,
})

jieying:addEffect(fk.EventAcquireSkill, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.skill.name == jieying.name and not player.chained and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player:setChainState(true)
  end,
})

jieying:addEffect(fk.BeforeChainStateChange, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieying.name) and player.chained
  end,
  on_use = function (self, event, target, player, data)
    data.prevented = true
  end,
})

jieying:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieying.name) and player.phase == Player.Finish
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and not p.chained
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = jieying.name,
        prompt = "#jieying-choose",
        cancelable = false,
      })[1]
      to:setChainState(true)
      if player.dead then return end
    end
    targets = table.filter(room.alive_players, function(p)
      return p.chained
    end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = #targets,
        targets = targets,
        skill_name = jieying.name,
        prompt = "#jieying-draw",
        cancelable = true,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if p:isAlive() then
            p:drawCards(1, jieying.name)
          end
        end
      end
    end
  end,
})

jieying:addEffect("maxcards", {
  correct_func = function(self, player)
    if player.chained then
      local num = #table.filter(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill(jieying.name)
      end)
      return 2 * num
    end
  end,
})

return jieying
