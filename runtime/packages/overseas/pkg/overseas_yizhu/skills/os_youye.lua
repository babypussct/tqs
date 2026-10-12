local osYouye = fk.CreateSkill {
  name = "os__youye",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__youye"] = "攸业",
  [":os__youye"] = "锁定技，其他角色的结束阶段，若其本回合没有对你造成过伤害，则你将牌堆顶的一张牌置于你的武将牌上，" ..
  "称为“蓄”（至多5张）。当你造成或受到伤害后，你将所有“蓄”分配给任意角色，若当前回合角色存活，其至少须获得一张。",

  ["os__poise"] = "蓄",
  ["#os__youye-give"] = "攸业：将至少一张“蓄”分配给 %dest，点击“确定”后再将剩余牌分配给任意角色",
  ["#os__youye-give2"] = "攸业：分配任意张“蓄”给任意角色，直到所有“蓄”分配完毕",

  ["$os__youye1"] = "筑城西疆，开万代太平。",
  ["$os__youye2"] = "镇边戍卫，许万民攸业。",
}

osYouye:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      target.phase == Player.Finish and
      player:hasSkill(osYouye.name) and
      #player:getPile("os__poise") < 5 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target and e.data.to == player
      end) == 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osYouye.name
    local room = player.room
    player:addToPile("os__poise", room:getNCards(1)[1], true, skillName, player)
  end,
})

local osYouyeDamageSpec = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(osYouye.name) and #player:getPile("os__poise") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osYouye.name
    local room = player.room
    local cards = player:getPile("os__poise")
    local current = room.current
    local toCurrent = {}
    if current:isAlive() then
      if #cards == 1 then
        toCurrent = cards
      else
        toCurrent = room:askToCards(
          player,
          {
            min_num = 1,
            max_num = #cards,
            pattern = ".|.|.|os__poise",
            skill_name = skillName,
            prompt = "#os__youye-give::" .. current.id,
            expand_pile = "os__poise",
          }
        )
      end
    end
    local residue = table.filter(cards, function(id) return not table.contains(toCurrent, id) end)
    if #residue == 0 then
      room:obtainCard(current, toCurrent, true, fk.ReasonGive, player, skillName)
    else
      local move = room:askToYiji(
        player,
        {
          cards = residue,
          targets = room.alive_players,
          min_num = #residue,
          max_num = #residue,
          skill_name = skillName,
          prompt = "#os__youye-give2",
          expand_pile = "os__poise",
          skip = true,
        }
      )
      move[current.id] = move[current.id] or {}
      table.insertTable(move[current.id], toCurrent)
      room:doYiji(move, player, skillName)
    end
  end,
}

osYouye:addEffect(fk.Damage, osYouyeDamageSpec)

osYouye:addEffect(fk.Damaged, osYouyeDamageSpec)

return osYouye
