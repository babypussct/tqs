local duduan = fk.CreateSkill {
  name = "duduan",
}

Fk:loadTranslationTable {
  ["duduan"] = "独断",
  [":duduan"] = "回合开始时，你可以摸一张牌，令你跳过本回合首个判定、摸牌、出牌、弃牌中的一个阶段（每个阶段每局游戏限跳过一次），" ..
      "然后交换另外两个阶段的顺序。",

  ["#duduan1-choice"] = "独断：选择要跳过的阶段",
  ["#duduan2-choice"] = "独断：选择本回合交换顺序的两个阶段",
  ["#duduan2-exchange"] = "%from 交换了 %arg 和 %arg2",
  ["#duduan2-skip"] = "%from 选择跳过了 %arg ",
  ["$duduan1"] = "图高帝之业，观曹操凶衅，不患贫而患不安。",
  ["$duduan2"] = "坐东南吴会，望九州离乱，不患寡而患不均。",
}

local duduanPhases = { "phase_judge", "phase_draw", "phase_play", "phase_discard" }

duduan:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
        target == player and
        player:hasSkill(duduan.name) and
        #player:getTableMark("duduan_skipped") < #duduanPhases
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = table.filter(duduanPhases, function(phase)
      return not table.contains(player:getTableMark("duduan_skipped"), phase)
    end)
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = duduan.name,
        prompt = "#duduan1-choice",
      }
    )

    if choice == "Cancel" then
      return false
    end

    event:setCostData(self, { choice = choice })
    room:addTableMark(player, "duduan_skipped", choice)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:sendLog {
      type = "#duduan2-skip",
      from = player.id,
      arg = choice,
    }
    player:skip(Util.PhaseStrMapper(choice))
    player:drawCards(1, duduan.name)
    if player.dead then return end
    local phases = table.filter(duduanPhases, function(phase) return phase ~= choice end)
    local choices = room:askToChoices(player, {
      choices = phases,
      min_num = 2,
      max_num = 2,
      skill_name = duduan.name,
      prompt = "#duduan2-choice",
      cancelable = false,
    })
    room:setPlayerMark(player, "duduan-turn", table.map(choices, function(phase)
      return Util.PhaseStrMapper(phase)
    end))
    room:sendLog {
      type = "#duduan2-exchange",
      from = player.id,
      arg = choices[1],
      arg2 = choices[2],
    }
  end,
})

duduan:addEffect(fk.EventPhaseChanging, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("duduan-turn"), data.phase)
  end,
  on_refresh = function(self, event, target, player, data)
    local phases = player:getTableMark("duduan-turn")
    data.phase = (data.phase == phases[1]) and phases[2] or phases[1]
  end,
})

return duduan
