local zhukou = fk.CreateSkill{
  name = "ty_heg__zhukou",
}
zhukou:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(zhukou.name)) then return end
    local room = player.room
    if room.current and room.current.phase == Player.Play then
      local damage_event = room.logic:getCurrentEvent()
      if not damage_event then return false end
      local events = room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end, Player.HistoryPhase)
      if #events > 0 and damage_event.id == events[1].id then
        local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
          return e.data.from == player
        end, Player.HistoryTurn)
        if n > 0 then
          event:setCostData(self, {num = n})
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhukou.name,
      prompt = "#ty_heg__zhukou:::" .. event:getCostData(self).num
    })
  end,
  on_use = function(self, event, target, player, data)
    local n = event:getCostData(self).num
    player:drawCards(math.min(5, n), zhukou.name)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__zhukou"] = "逐寇",
  [":ty_heg__zhukou"] = "当你于每回合的出牌阶段首次造成伤害后，你可摸X张牌（X为本回合你已使用的牌数且至多为5）。",

  ["#ty_heg__zhukou"] = "逐寇：你可摸 %arg 张牌",

  ["$ty_heg__zhukou1"] = "草莽贼寇，不过如此。",
  ["$ty_heg__zhukou2"] = "轻装上阵，利剑出鞘。",
}

return zhukou
