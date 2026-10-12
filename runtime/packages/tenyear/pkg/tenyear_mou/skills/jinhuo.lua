
local jinhuo = fk.CreateSkill{
  name = "jinhuo",
}

Fk:loadTranslationTable{
  ["jinhuo"] = "矜祸",
  [":jinhuo"] = "你获得其他角色或其他角色获得你的牌时，你可以将手牌摸至体力上限。然后若你的手牌数比该角色多，其本回合非锁定技失效。",

  ["#jinhuo-invoke"] = "矜祸：你可以将手牌摸至体力上限，若手牌比 %dest 多，其本回合非锁定技失效",

  ["$jinhuo1"] = "",
  ["$jinhuo2"] = "",
}

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getTargets = function(player, data)
  local room = player.room
  local targets = {}
  for _, move in ipairs(data) do
    if move.from and move.from ~= player and move.to == player and
      not table.contains(targets, move.from) then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
          table.insert(targets, move.from)
          break
        end
      end
    elseif move.from == player and move.to and move.to ~= player and
      not table.contains(targets, move.to) then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
          table.insert(targets, move.to)
          break
        end
      end
    end
  end
  return targets
end

jinhuo:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  trigger_times = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    if targets then
      return #table.filter(targets.unDone, Util.TrueFunc) + (event.invoked_times[self.name] or 0)
    else
      return #getTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jinhuo.name) and
      player:usedSkillTimes(jinhuo.name, Player.HistoryTurn) == 0
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
        to = p
        break
      end
    else
      targets = getTargets(player, data)
      if #targets > 0 then
        room:sortByAction(targets)
        to = table.remove(targets, 1)
        event:setSkillData(self, jinhuo.name .. ":" .. player.id, { done = { to }, unDone = targets })
      end
    end
    if to and player.room:askToSkillInvoke(player, {
      skill_name = jinhuo.name,
      prompt = "#jinhuo-invoke::"..to.id,
    }) then
      event:setCostData(self, { tos = { to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if player.maxHp > player:getHandcardNum() then
      player:drawCards(player.maxHp - player:getHandcardNum(), jinhuo.name)
    end
    if player:getHandcardNum() > to:getHandcardNum() and not to.dead then
      room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
    end
  end,
})

return jinhuo
