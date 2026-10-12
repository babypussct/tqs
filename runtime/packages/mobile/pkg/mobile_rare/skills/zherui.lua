local zherui = fk.CreateSkill {
  name = "zherui",
}

Fk:loadTranslationTable{
  ["zherui"] = "折锐",
  [":zherui"] = "装备区有“陷坚”牌的角色使用【杀】指定目标后，你对其发动一次由其选择的〖陷坚〗；"..
  "当一名角色失去装备区的一张“陷坚”牌后，你对其造成1点伤害。",

  ["$zherui1"] = "乐进在此，谁敢与吾决死？",
  ["$zherui2"] = "吾虽力竭，犹能再战！",
  ["$zherui3"] = "彼众我寡，正可显名！",
  ["$zherui4"] = "非好杀戮，实止干戈。",
}

zherui:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zherui.name) and
      data.card.trueName == "slash" and data.firstTarget and
      table.find(target:getEquipCards(), function (card)
        return card.trueName == "xianjian"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(#target:getCardIds("ej"), 1)
    local choice = room:askToChoice(target, {
      choices = { "xianjian_draw:"..player.id..":"..target.id..":"..n, "xianjian_put::"..target.id },
      skill_name = "xianjian",
    })
    data.extra_data = data.extra_data or {}
    if choice:startsWith("xianjian_draw") then
      data.extra_data.xianjian1 = { player, target }
      player:drawCards(1, "xianjian")
      if not target:isNude() then
        room:askToDiscard(target, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = "xianjian",
          cancelable = false,
        })
      end
    else
      data.extra_data.xianjian2 = { player, target }
    end
    room:addSkill("xianjian")
  end,
})

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
    if move.from then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerEquip and info.beforeCard.trueName == "xianjian" then
          table.insert(targets, move.from)
        end
      end
    end
  end
  return table.filter(targets, function (p)
    return targetFilter(p)
  end)
end

zherui:addEffect(fk.AfterCardsMove, {
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
    return player:hasSkill(zherui.name)
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
    if to then
      event:setCostData(self, { tos = { to }})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = zherui.name,
    }
  end,
})

return zherui
