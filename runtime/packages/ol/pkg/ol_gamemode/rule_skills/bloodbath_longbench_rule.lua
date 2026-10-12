local rule = fk.CreateSkill {
  name = "#bloodbath_longbench_rule&",
}

Fk:loadTranslationTable {
  ["#bloodbath_longbench_rule&"] = "血战长坂坡",
}

local function findParent(self, eventTypes)
  if table.contains(eventTypes, self.event) then return self end
  local e = self.parent
  local l = 1
  while e do
    if table.contains(eventTypes, e.event) then return e end
    e = e.parent
    l = l + 1
  end
  return nil
end

---因技能导致体力上限变更时，固定到令体力上限不会小于3，同时不会大于5的数值
rule:addEffect(fk.BeforeMaxHpChanged, {
  priority = 0,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.num ~= 0 then
      local skillEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
      if skillEvent then
        local skillData = skillEvent.data
        return skillData.skill and skillData.skill:isPlayerSkill(skillData.who, true)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local final = player.maxHp + data.num
    if final > 5 then
      data.num = math.max(5 - player.maxHp, 0)
    elseif final < 3 then
      data.num = math.min(3 - player.maxHp, 0)
    end
  end
})

---背面朝上时因自己的技能翻至正面朝上时，取消之。
rule:addEffect(fk.BeforeTurnOver, {
  priority = 0,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.faceup then
      if data.reason ~= "game_rule" then
        return data.who == player or player:hasSkill(data.reason, true)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.prevented = true
  end
})

---屏蔽转化牌
rule:addEffect(fk.SkillEffect, {
  can_refresh = function(self, event, target, player, data)
    if target == player and data.skill and data.skill:isPlayerSkill(player, true) then
      local parentUseData = findParent(player.room.logic:getCurrentEvent(), { GameEvent.UseCard, GameEvent.RespondCard })
      if parentUseData then
        local cardUseEvent = parentUseData.data
        return cardUseEvent.card and cardUseEvent.card:isVirtual()
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "_longbench_ban-turn", data.skill.name)
  end
})
--[[
---@type TrigSkelSpec<fun(self: TriggerSkill, event: UseCardEvent|RespondCardEvent, target: ServerPlayer, player: ServerPlayer, data: UseCardData|RespondCardData):any>
local add_spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and data.card:isVirtual()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, to in ipairs(player.room:getAlivePlayers()) do
      data.lb_virtualban = true
      player.room:addPlayerMark(to, "_longbench_banning")
      data.extra_data = data.extra_data or {}
      data.extra_data.lb_virtualban = data.extra_data.lb_virtualban or {}
      table.insert(data.extra_data.lb_virtualban, to)
    end
  end
}
---@type TrigSkelSpec<fun(self: TriggerSkill, event: UseCardEvent|RespondCardEvent, target: ServerPlayer, player: ServerPlayer, data: UseCardData|RespondCardData):any>
local remove_spec = {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.lb_virtualban and table.contains(data.extra_data.lb_virtualban, player)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    while table.removeOne(data.extra_data.lb_virtualban, player) do
      room:removePlayerMark(player, "_longbench_banning")
    end
  end
}
local effect_remove = {
  can_refresh = function(self, event, target, player, data)
    local logic = player.room.logic
    local game_event = logic:getCurrentEvent()
    if game_event.event ~= GameEvent.CardEffect then return false end
    local effect = game_event.data
    if player ~= effect.to or effect.lb_virtualban_clean then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.UseCard and game_event.event ~= GameEvent.RespondCard then return false end
    local use = game_event.data

    return use.additionalEffect == 0 and
      use.extra_data and use.extra_data.lb_virtualban and table.contains(use.extra_data.lb_virtualban, player)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local logic = room.logic
    local cardEffectEvent = logic:getCurrentEvent():findParent(GameEvent.CardEffect, true)
    if cardEffectEvent == nil then return end
    local effect = cardEffectEvent.data
    effect.lb_virtualban_clean = true
    table.removeOne(effect.extra_data.lb_virtualban, player)
    room:removePlayerMark(player, "_longbench_banning")
  end
}
rule:addEffect(fk.PreCardUse, add_spec)
rule:addEffect(fk.PreCardRespond, add_spec)
rule:addEffect(fk.CardUseFinished, remove_spec)
rule:addEffect(fk.CardRespondFinished, remove_spec)
rule:addEffect(fk.CardEffectFinished, effect_remove)
rule:addEffect(fk.CardEffectCancelledOut, effect_remove)
rule:addEffect(fk.BeforeHpChanged, {
  can_refresh = function(self, event, target, player, data)
    local logic = player.room.logic
    local game_event = logic:getCurrentEvent()
    if game_event.event ~= GameEvent.ChangeHp then return false end
    local hpChangedData = game_event.data
    if hpChangedData.who ~= player or hpChangedData.reason ~= "damage" then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.Damage then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.SkillEffect or not table.contains(player:getTableMark("_longbench_ban-turn"), game_event.data.skill.name) then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.CardEffect then return false end
    local effect = game_event.data
    if player ~= effect.to or effect.lb_virtualban_clean then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.UseCard and game_event.event ~= GameEvent.RespondCard then return false end
    local use = game_event.data

    return use.additionalEffect == 0 and
      use.extra_data and use.extra_data.lb_virtualban and table.contains(use.extra_data.lb_virtualban, player)
  end,
  on_refresh = effect_remove.on_refresh,
})
rule:addEffect(fk.DamageFinished, {
  can_refresh = function(self, event, target, player, data)
    local logic = player.room.logic
    local game_event = logic:getCurrentEvent()
    if data.card == nil or data.to ~= player then return false end
    if game_event.event ~= GameEvent.SkillEffect or not table.contains(player:getTableMark("_longbench_ban-turn"), game_event.data.skill.name) then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.CardEffect then return false end
    local effect = game_event.data
    if player ~= effect.to or effect.lb_virtualban_clean then return false end
    game_event = game_event.parent
    if game_event.event ~= GameEvent.UseCard and game_event.event ~= GameEvent.RespondCard then return false end
    local use = game_event.data

    return use.additionalEffect == 0 and
      use.extra_data and use.extra_data.lb_virtualban and table.contains(use.extra_data.lb_virtualban, player)
  end,
  on_refresh = effect_remove.on_refresh,
})
]]
rule:addEffect('invalidity', {
  invalidity_func = function(self, player, skill)
    if skill:getSkeleton() and skill:isPlayerSkill(player, true) then
      -- if player:getMark("_longbench_banning") > 0 then return true end

      if not RoomInstance then return end
      local logic = RoomInstance.logic
      local event = logic:getCurrentEvent()
      local card = nil
      repeat
        local data = event.data
        if event.event == GameEvent.Damage then
          ---@cast data DamageData
          if not data.card then return false end
          if not data.card:isVirtual() then return false end
          card = data.card
          break
        elseif event.event == GameEvent.CardEffect then
          ---@cast data CardEffectData
          if not data.card then return false end
          if not data.card:isVirtual() then return false end
          card = data.card
          break
        elseif event.event == GameEvent.UseCard then
          ---@cast data UseCardData
          if not data.card then return false end
          if not data.card:isVirtual() then return false end
          card = data.card
          break
        elseif event.event == GameEvent.RespondCard then
          ---@cast data UseCardData
          if not data.card then return false end
          if not data.card:isVirtual() then return false end
          card = data.card
          break
        end
        event = event.parent
      until event == nil
      if card then
        if table.contains(player:getTableMark("_longbench_ban-turn"), skill:getSkeleton().name) then
          return true
        end
      end
    end
  end
})

return rule
