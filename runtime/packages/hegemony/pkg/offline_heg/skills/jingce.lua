local jingce = fk.CreateSkill {
  name = "ofl_heg__jingce",
}

Fk:loadTranslationTable{
  ["ofl_heg__jingce"] = "精策",
  [":ofl_heg__jingce"] = "回合结束时，若本回合进入弃牌堆的牌数不小于X，你可以执行一个额外的摸牌阶段；"..
  "若你本回合使用过的牌数不小于X，你可以执行一个额外的出牌阶段（X为你的体力值）。",

  ["#ofl_heg__jingce-choice"] = "精策：选择执行的额外阶段",

  ["$ofl_heg__jingce1"] = "精细入微，策敌制胜。",
  ["$ofl_heg__jingce2"] = "妙策如神，精兵强将，安有不胜之理？",
}

jingce:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jingce.name) and player.phase == Player.Finish then
      local choices = {}
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            n = n + #move.moveInfo
            if n >= player.hp then
              return true
            end
          end
        end
      end, Player.HistoryTurn)
      if n >= player.hp then
        table.insert(choices, "phase_draw")
      end
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, player.hp, function(e)
        return e.data.from == player
      end, Player.HistoryTurn) == player.hp then
        table.insert(choices, "phase_play")
      end
      if #choices > 0 then
        event:setCostData(self, { choices = choices })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices
    choices = room:askToChoices(player, {
      choices = choices,
      min_num = 1,
      max_num = 2,
      skill_name = jingce.name,
      prompt = "#ofl_heg__jingce-choice",
      cancelable = true,
    })
    if #choices > 0 then
      event:setCostData(self, { choices = choices })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choices = event:getCostData(self).choices
    if table.contains(choices, "phase_play") then
      player:gainAnExtraPhase(Player.Play)
    end
    if table.contains(choices, "phase_draw") then
      player:gainAnExtraPhase(Player.Draw)
    end
  end,
})

return jingce
