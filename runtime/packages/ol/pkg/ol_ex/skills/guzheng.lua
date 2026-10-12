
local guzheng = fk.CreateSkill {
  name = "ol_ex__guzheng",
}

Fk:loadTranslationTable{
  ["ol_ex__guzheng"] = "固政",
  [":ol_ex__guzheng"] = "每阶段限一次，当其他角色的至少两张牌因弃置而置入弃牌堆后，你可以令其获得其中一张牌，然后你可以获得剩余牌。",

  ["#ol_ex__guzheng-invoke"] = "固政：你可以令%dest获得其此次弃置的牌中的一张，然后你获得剩余牌",
  ["#ol_ex__guzheng-choose"] = "固政：你可以令一名角色获得其此次弃置的牌中的一张，然后你获得剩余牌",
  ["#guzheng-title"] = "固政：选择一张牌还给 %dest",
  ["guzheng_yes"] = "确定，获得剩余牌",
  ["guzheng_no"] = "确定，不获得剩余牌",

  ["$ol_ex__guzheng1"] = "兴国为任，可驱百里之行。",
  ["$ol_ex__guzheng2"] = "固政之责，在君亦在臣。",
}

---@param target ServerPlayer
---@param data MoveCardsData[]
---@return integer[]
local targetFilter = function(target, data)
  local cards = {}
  for _, move in ipairs(data) do
    if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from and move.from == target then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
          table.insert(cards, info.cardId)
        end
      end
    end
  end
  local room = target.room
  return room.logic:moveCardsHoldingAreaCheck(table.filter(cards, function (id)
    return room:getCardArea(id) == Card.DiscardPile
  end))
end

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getTargets = function(player, data)
  local dat = {}
  for _, move in ipairs(data) do
    if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from and move.from ~= player then
      local value = dat[move.from] or {}
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
          table.insert(value, info.cardId)
        end
      end
      dat[move.from] = value
    end
  end
  local targets, ids = {}, {}
  local room = player.room
  for key, value in pairs(dat) do
    if not key.dead and #value > 1 then
      ids = room.logic:moveCardsHoldingAreaCheck(table.filter(value, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end))
      if #ids > 0 then
        table.insert(targets, key)
      end
    end
  end
  return targets
end

guzheng:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  trigger_times = function(self, event, target, player, data)
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    if targets then
      return #table.filter(targets.unDone, function(p)
        return #targetFilter(p, data) > 0
      end) + (event.invoked_times[self.name] or 0)
    else
      return #getTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guzheng.name) and player:usedSkillTimes(guzheng.name, Player.HistoryPhase) < 1 and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Phase, true) ~= nil
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    local to, cards
    if targets then
      while #targets.unDone > 0 do
        local p = table.remove(targets.unDone, 1)
        table.insert(targets.done, p)
        cards = targetFilter(p, data)
        if #cards > 0 then
          to = p
          break
        end
      end
    else
      targets = getTargets(player, data)
      if #targets > 0 then
        room:sortByAction(targets)
        to = table.remove(targets, 1)
        cards = targetFilter(to, data)
        event:setSkillData(self, self.name .. ":" .. player.id, { done = { to }, unDone = targets })
      end
    end
    if to and room:askToSkillInvoke(player, {
      skill_name = guzheng.name,
      prompt = "#ol_ex__guzheng-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    local to_return = room:tableRandomPick(cards, 1)
    local choice = "guzheng_no"
    if #cards > 1 then
      to_return, choice = room:askToChooseCardsAndChoice(player, {
        cards = cards,
        choices = {"guzheng_yes", "guzheng_no"},
        skill_name = guzheng.name,
        prompt = "#guzheng-title::" .. to.id
      })
    end
    local moveInfos = {}
    table.insert(moveInfos, {
      ids = to_return,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player,
      skillName = guzheng.name,
    })
    table.removeOne(cards, to_return[1])
    if choice == "guzheng_yes" and #cards > 0 then
      table.insert(moveInfos, {
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = guzheng.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

return guzheng
