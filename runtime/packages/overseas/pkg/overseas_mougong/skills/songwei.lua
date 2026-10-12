local songwei = fk.CreateSkill {
  name = "os_mou__songwei",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os_mou__songwei"] = "颂威",
  [":os_mou__songwei"] = "主公技，锁定技，其他魏势力角色的回合开始时，你摸X张牌（X为本轮未执行过回合的角色数且至多为3）。",

  ["$os_mou__songwei1"] = "文治武功，上过高祖，下辟千秋！",
  ["$os_mou__songwei2"] = "圣谟丕显，化成天下！",
}

songwei:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    if not (target ~= player and target.kingdom == "wei" and player:hasSkill(songwei.name)) then
      return false
    end

    local players = {}
    player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function(e)
      table.insertIfNeed(players, e.data.who)
    end, Player.HistoryRound)

    local num = math.min(
      3,
      #table.filter(player.room.alive_players, function(p) return not table.contains(players, p) end)
    )

    if num > 0 then
      event:setCostData(self, { num = num })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).num, songwei.name)
  end,
})

return songwei
