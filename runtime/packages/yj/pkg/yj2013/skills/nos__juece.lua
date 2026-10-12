local juece = fk.CreateSkill {
  name = "nos__juece",
}

Fk:loadTranslationTable{
  ["nos__juece"] = "绝策",
  [":nos__juece"] = "你的回合内，当一名角色失去最后的手牌后，你可以对其造成1点伤害。",

  ["#nos__juece-invoke"] = "绝策：你可以对 %dest 造成1点伤害",

  ["$nos__juece1"] = "我，最喜欢落井下石。",
  ["$nos__juece2"] = "一无所有？那就拿命来填！",
}

---@param player ServerPlayer
---@return boolean
local targetFilter = function(player)
  return not player.dead
end

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getTargets = function(player, data)
  local room = player.room
  local targets = {}
  for _, move in ipairs(data) do
    if move.from and move.from:isKongcheng() and not table.contains(targets, move.from) then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then
          table.insert(targets, move.from)
          break
        end
      end
    end
  end
  return table.filter(targets, function (p)
    return targetFilter(p)
  end)
end

juece:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  trigger_times = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    if targets then
      return #table.filter(targets.unDone, function (p)
        return targetFilter(p)
      end) + (event.invoked_times[self.name] or 0)
    else
      return #getTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player.room:getCurrent() == player and player:hasSkill(juece.name)
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    local to
    if targets then
      while #targets.unDone > 0 do
        local p = table.remove(targets.unDone, 1)
        table.insert(targets.done, p)
        if targetFilter(p) then
          to = p
          break
        end
      end
    else
      targets = getTargets(player, data)
      if #targets > 0 then
        room:sortByAction(targets)
        to = table.remove(targets, 1)
        event:setSkillData(self, self.name .. ":" .. player.id, { done = { to }, unDone = targets })
      end
    end
    if to and room:askToSkillInvoke(player, {
      skill_name = juece.name,
      prompt = "#nos__juece-invoke::"..to.id,
    }) then
      event:setCostData(self, { tos = { to }})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = juece.name,
    }
  end,
})

juece:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return ai:getBenefitOfEvents(function(logic)
      logic:damage{
        from = ai.player,
        to = target,
        damage = 1,
      }
    end) >= 0
  end,
})

return juece
