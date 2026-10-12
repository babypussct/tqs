local suizheng = fk.CreateSkill {
  name = "os2__suizheng",
}

Fk:loadTranslationTable{
  ["os2__suizheng"] = "随征",
  [":os2__suizheng"] = "结束阶段，你可以选择一名角色，该角色下个回合出牌阶段使用【杀】无距离限制且可以多使用两张【杀】；"..
  "其出牌阶段结束时，你可以视为对其本阶段造成过伤害的另一名其他角色使用一张【杀】。",

  ["@@os2__suizheng-turn"] = "随征",
  ["#os2__suizheng-choose"] = "随征：令一名角色下回合出牌阶段使用【杀】无距离限制且次数+2",
  ["#os2__suizheng-slash"] = "随征：你可以视为对其中一名角色使用【杀】",
  ["@@os2__suizheng"] = "随征",

  ["$os2__suizheng1"] = "一哄而上，旋倾即破。",
  ["$os2__suizheng2"] = "诸将随征，获匪其丑。",
}

suizheng:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(suizheng.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      skill_name = suizheng.name,
      prompt = "#os2__suizheng-choose",
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
    room:addTableMark(to, "@@os2__suizheng", player.id)
  end,
})

suizheng:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(suizheng.name) and target.phase == Player.Play and
      table.contains(target:getTableMark("@@os2__suizheng-turn"), player.id) then
      local targets = {}
      player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        if damage.from == target and damage.to ~= player and damage.to ~= target and
          player:canUseTo(Fk:cloneCard("slash"), damage.to, { bypass_distances = true, bypass_times = true }) then
          table.insertIfNeed(targets, damage.to)
        end
      end, Player.HistoryPhase)
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = suizheng.name,
      prompt = "#os2__suizheng-slash",
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
    room:useVirtualCard("slash", nil, player, to, suizheng.name, true)
  end,
})

suizheng:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@os2__suizheng") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@os2__suizheng-turn", player:getMark("@@os2__suizheng"))
    room:setPlayerMark(player, "@@os2__suizheng", 0)
  end,
})

suizheng:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    if card and card.trueName == "slash" and player:getMark("@@os2__suizheng-turn") ~= 0 and
      scope == Player.HistoryPhase and player.phase == Player.Play then
      return 2 * #player:getTableMark("@@os2__suizheng-turn")
    end
  end,
  bypass_distances = function(self, player, skill, card)
    return card and card.trueName == "slash" and player:getMark("@@os2__suizheng-turn") ~= 0 and player.phase == Player.Play
  end,
})

return suizheng
