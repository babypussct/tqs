
local guanchong = fk.CreateSkill {
  name = "guanchong",
}

Fk:loadTranslationTable {
  ["guanchong"] = "冠宠",
  [":guanchong"] = "每回合限一次，其他角色在摸牌阶段外单次获得牌数超过一时，你可以令其交给你一张指定类型的手牌，若其没有此类型的手牌，"..
  "你摸一张牌，你因此技能获得牌后所有手牌点数+1。",

  ["#guanchong-invoke"] = "冠宠：你可以令 %dest 交给你一张指定类型的手牌",
  ["#guanchong-give"] = "冠宠：请交给 %src 一张%arg",
  ["@guanchong-inhand"] = "点数+",

  ["$guanchong1"] = "",
  ["$guanchong2"] = "",
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
    if move.to and move.to ~= player and move.to.phase ~= Player.Draw and #move.moveInfo > 1 and
      not table.contains(targets, move.to) and move.toArea == Card.PlayerHand then
      table.insert(targets, move.to)
    end
  end
  return table.filter(targets, function (p)
    return targetFilter(p)
  end)
end

guanchong:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
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
    return player:hasSkill(guanchong.name) and
      player:usedSkillTimes(guanchong.name, Player.HistoryTurn) == 0
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
      local choice = room:askToChoice(player, {
        skill_name = guanchong.name,
        prompt = "#guanchong-invoke::"..to.id,
        choices = { "basic", "trick", "equip" },
        cancelable = true,
      })
      if choice ~= "Cancel" then
        event:setCostData(self, { tos = { to }, choice = choice })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = guanchong.name,
      pattern = ".|.|.|hand|.|"..choice,
      prompt = "#guanchong-give:"..player.id.."::"..choice,
      cancelable = not table.find(to:getCardIds("h"), function (id)
        return Fk:getCardById(id):getTypeString() == choice
      end),
    })
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, guanchong.name, nil, false, to)
    else
      --[[
      card = room:getCardsFromPileByRule(".|.|.|.|.|"..choice)
      if #card == 0 then
        card = room:getCardsFromPileByRule(".|.|.|.|.|"..choice, 1, "discardPile")
      end
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, guanchong.name, nil, false, player)
      end]]
      card = player:drawCards(1, guanchong.name)
    end
    if #card > 0 and not player:isKongcheng() then
      for _, id in ipairs(player:getCardIds("h")) do
        room:addCardMark(Fk:getCardById(id), "@guanchong-inhand", 1)
      end
    end
  end,
})

guanchong:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@guanchong-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card.name, card.suit, card.number + card:getMark("@guanchong-inhand"))
  end,
})

return guanchong
