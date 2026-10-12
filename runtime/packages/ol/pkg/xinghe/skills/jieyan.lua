local jieyan = fk.CreateSkill{
  name = "jieyan",
}

Fk:loadTranslationTable{
  ["jieyan"] = "节言",
  [":jieyan"] = "一名角色一次失去恰好两张手牌后，你可以与其从牌堆两端各摸一张牌并展示，若花色不同，此技能本回合失效。",

  ["#jieyan-invoke"] = "节言：是否与 %dest 从牌堆两端各摸一张牌？",

  ["$jieyan1"] = "父高居殿陛，德当配其位。",
  ["$jieyan2"] = "君子善行，阿耶固君子，应有所不为。",
}

---@param target ServerPlayer
---@return boolean
local targetFilter = function(target)
  return not target.dead
end

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getTargets = function(player, data)
  local dat = {}
  for _, move in ipairs(data) do
    if move.from then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then
          dat[move.from] = (dat[move.from] or 0) + 1
        end
      end
    end
  end
  local targets = {}
  for p, n in pairs(dat) do
    if n == 2 then
      table.insert(targets, p)
    end
  end
  return table.filter(targets, function (p)
    return targetFilter(p)
  end)
end

jieyan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  trigger_times = function(self, event, target, player, data)
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    if targets then
      return #table.filter(targets.unDone, function(p)
        return targetFilter(p)
      end) + (event.invoked_times[self.name] or 0)
    else
      return #getTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jieyan.name)
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
      skill_name = jieyan.name,
      prompt = "#jieyan-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local a = player.seat
    local b = to.seat
    local c = room.current.seat
    if a < c then
      a = a + c
    end
    if b < c then
      b = b + c
    end
    local playerA, playerB = to, player
    if a < b then
      playerA = player
      playerB = to
    end
    local cards = playerA:drawCards(1, jieyan.name)
    local suit = Card.NoSuit
    local invalidateSkill = false
    if #cards > 0 then
      suit = Fk:getCardById(cards[1]).suit
      if not playerA.dead and table.contains(playerA:getCardIds("h"), cards[1]) then
        playerA:showCards(cards[1])
      end
    end
    if not playerB.dead then
      cards = playerB:drawCards(1, jieyan.name, "bottom")
      if #cards > 0 then
        if suit == Card.NoSuit or suit ~= Fk:getCardById(cards[1]).suit then
          invalidateSkill = true
        end
        if not playerB.dead and table.contains(playerB:getCardIds("h"), cards[1]) then
          playerB:showCards(cards[1])
        end
      end
    end
    if player:hasSkill(jieyan.name, true) and room:getCurrent() and invalidateSkill then
      room:invalidateSkill(player, jieyan.name, "-turn")
    end
  end,
})

return jieyan
