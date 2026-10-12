local liaoyil = fk.CreateSkill {
  name = "liaoyil",
}

Fk:loadTranslationTable{
  ["liaoyil"] = "料意",
  [":liaoyil"] = "当前回合角色本回合首次对你使用牌时，你可以选择一项：1.摸一张牌；2.令此牌对你无效。"..
  "然后你不能再对其发动此技能。",

  ["#liaoyil-invoke"] = "料意：你可以选择一项",
  ["liaoyil_nullify"] = "%arg对你无效",

  ["$liaoyil1"] = "君之所谋，吾已了然于胸。",
  ["$liaoyil2"] = "徒劳之举，吾早有应对之策。",
}

liaoyil:addEffect(fk.CardUsing, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player.room:getCurrent() and player:hasSkill(liaoyil.name) and
      table.contains(data.tos, player) and not table.contains(player:getTableMark(liaoyil.name), target) then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == target and table.contains(use.tos, player)
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "draw1", "liaoyil_nullify:::"..data.card:toLogString(), "Cancel" },
      skill_name = liaoyil.name,
      prompt = "#liaoyil-invoke",
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { target }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, liaoyil.name, target)
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      player:drawCards(1, liaoyil.name)
    else
      data.nullifiedTargets = data.nullifiedTargets or {}
      table.insertIfNeed(data.nullifiedTargets, player)
    end
  end,
})

liaoyil:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, liaoyil.name, 0)
end)

return liaoyil
