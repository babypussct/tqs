local osJieqiu = fk.CreateSkill {
  name = "os__jieqiu"
}

Fk:loadTranslationTable{
  ["os__jieqiu"] = "劫囚",
  [":os__jieqiu"] = "出牌阶段限一次，你可选择一名所有装备栏均未被废除的其他角色，废除其所有装备栏，然后其摸X张牌（X为废除前其装备区里的牌数）。" ..
  "其弃牌阶段结束时，其恢复等同于此阶段弃置手牌数量的装备栏。其回合结束时，若仍有装备栏被废除，则你可执行一个额外回合（每轮限一次）。",

  ["@os__jieqiu"] = "被劫囚",
  ["#os__jieqiu-ask"] = "劫囚：你可执行一个额外回合",
  ["#os__jieqiu-choice"] = "劫囚：恢复 %arg 个装备栏",
  ["#os__jieqiu"] = "选择一名所有装备栏均未被废除的其他角色，废除其所有装备栏",

  ["$os__jieqiu1"] = "元直莫慌，石韬来也！",
  ["$os__jieqiu2"] = "一群鼠辈，焉能挡我等去路！",
}

--- 获取被废除的装备栏
---@param player Player
local function getSealedEquipSlot(player)
  local all_slots = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
  return table.filter(all_slots, function(slot) return table.contains(player.sealedSlots, slot) end)
end

osJieqiu:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#os__jieqiu",
  times = function (self, player)
    return 1 - player:usedSkillTimes(osJieqiu.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(osJieqiu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #getSealedEquipSlot(to_select) == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local num = #target:getCardIds("e")
    room:abortPlayerArea(target, target.equipSlots)
    if target:isAlive() then
      room:setPlayerMark(target, "@os__jieqiu", player)
      target:drawCards(num, osJieqiu.name)
    end
  end,
})

osJieqiu:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target:getMark("@os__jieqiu") == 0 or not target:isAlive() then return end
    if target == player and target.phase == Player.Discard then
      local num = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == target and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                num = num + 1
              end
            end
          end
        end
        return false
      end, Player.HistoryPhase)
      if num > 0 then
        event:setCostData(self, num)
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = event:getCostData(self)
    local all_choices = getSealedEquipSlot(player)
    if #all_choices > 0 then
      local choices_params = {
        choices = all_choices,
        min_num = num,
        max_num = num,
        skill_name = osJieqiu.name,
        prompt = "#os__jieqiu-choice:::" .. num,
        cancelable = false,
      }
      local choices = room:askToChoices(player, choices_params)
      room:resumePlayerArea(player, choices)
    end
  end,
})

osJieqiu:addEffect(fk.TurnEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target:getMark("@os__jieqiu") == 0 or not target:isAlive() then return end

    return target:getMark("@os__jieqiu") == player and player:isAlive() and player:usedEffectTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = osJieqiu.name,
      prompt = "#os__jieqiu-ask"
    }) then
      event:setCostData(self, { tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn()
  end,
})

osJieqiu:addEffect(fk.AreaResumed, {
  can_refresh = function(self, event, target, player, data)
    return player == target and #getSealedEquipSlot(player) == 0 and player:getMark("@os__jieqiu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__jieqiu", 0)
  end,
})

return osJieqiu
