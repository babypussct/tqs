local wumei = fk.CreateSkill {
  name = "wumei",
}

Fk:loadTranslationTable{
  ["wumei"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，所有存活角色将体力值调整为此额外回合开始时的数值。",

  ["@@wumei"] = "寤寐",
  ["#wumei-choose"] = "寤寐：你可以令一名角色执行一个额外的回合",

  ["$wumei1"] = "大梦若期，皆付一枕黄粱。",
  ["$wumei2"] = "日所思之，故夜所梦之。",
}

wumei:addEffect(fk.BeforeTurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wumei.name) and
      player:usedSkillTimes(wumei.name, Player.HistoryRound) == 0 and not data.turn_end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#wumei-choose",
      skill_name = wumei.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not data.turn_end then
      data.turn_end = true
      player:gainAnExtraTurn(true, data.reason, table.map(data.phase_table, function(e) return e.phase end), data.extra_data)
    end
    local to = event:getCostData(self).tos[1]
    local hp_record = {}
    for _, p in ipairs(room.alive_players) do
      table.insert(hp_record, {p.id, p.hp})
    end
    room:setPlayerMark(to, "@@wumei", 1)
    to:gainAnExtraTurn(true, wumei.name, nil, {
      wumei_source = player,
      wumei_record = hp_record
    })
  end,
})

wumei:addEffect(fk.TurnEnd, {
  anim_type = "special",
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.reason == wumei.name and
      data.extra_data and data.extra_data.wumei_source and data.extra_data.wumei_record and
      not data.extra_data.wumei_source.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local hp_record = data.extra_data.wumei_record
    if type(hp_record) ~= "table" then return false end
    for _, p in ipairs(room:getAlivePlayers()) do
      local p_record = table.find(hp_record, function (sub_record)
        return #sub_record == 2 and sub_record[1] == p.id
      end)
      if p_record then
        p.hp = math.min(p.maxHp, p_record[2])
        room:broadcastProperty(p, "hp")
      end
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@wumei", 0)
  end,
})

wumei:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local ret = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic.benefit = ai:needHelp(p, "h|e")
      end,
    })
    if ret then
      return ret
    else
      return { ai.player }
    end
  end,
})

return wumei
