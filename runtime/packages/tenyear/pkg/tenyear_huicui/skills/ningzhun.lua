local ningzhun = fk.CreateSkill {
  name = "ningzhun",
  max_branches_use_time = {
    ["ningzhun_+1"] = {
      [Player.HistoryTurn] = 1,
    },
    ["ningzhun_-1"] = {
      [Player.HistoryTurn] = 1,
    },
    ["ningzhun_move"] = {
      [Player.HistoryTurn] = 1,
    },
  },
}

Fk:loadTranslationTable{
  ["ningzhun"] = "凝准",
  [":ningzhun"] = "每回合每项限一次，当你一回合每使用两张牌结算结束后，你可以选择一项：1.攻击范围-1；2.攻击范围+1；3.移动场上一张牌。" ..
  "本回合你每执行过其中两项，此技能视为未发动过。",

  ["ningzhun_+1"] = "攻击范围+1",
  ["ningzhun_-1"] = "攻击范围-1",
  ["ningzhun_move"] = "移动场上一张牌",
  ["@ningzhun_buff"] = "攻击范围",

  ["$ningzhun1"] = "枪削虎王冠，百步之外必取尔首级。",
  ["$ningzhun2"] = "壮士不动则已，动则袭如雷霆！",
}

ningzhun:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ningzhun.name) and
      data.card.sub_type ~= Card.SubtypeDelayedTrick and
      player:getMark("ningzhun_used-turn") > 1 and
      (ningzhun:withinBranchTimesLimit(player, "ningzhun_+1") or
      ningzhun:withinBranchTimesLimit(player, "ningzhun_-1") or
      (ningzhun:withinBranchTimesLimit(player, "ningzhun_move") and #player.room:canMoveCardInBoard("ej") > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    if ningzhun:withinBranchTimesLimit(player, "ningzhun_+1") then
      table.insert(choices, "ningzhun_+1")
    end
    if ningzhun:withinBranchTimesLimit(player, "ningzhun_-1") then
      table.insert(choices, "ningzhun_-1")
    end
    if ningzhun:withinBranchTimesLimit(player, "ningzhun_move") and #player.room:canMoveCardInBoard("ej") > 0 then
      table.insert(choices, "ningzhun_move")
    end

    if #choices == 0 then
      return false
    end

    table.insert(choices, "Cancel")

    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        all_choices = { "ningzhun_+1", "ningzhun_-1", "ningzhun_move", "Cancel" },
        skill_name = ningzhun.name,
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { history_branch = choice })
      player.room:setPlayerMark(player, "ningzhun_used-turn", 0)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = ningzhun.name
    local room = player.room
    local choice = event:getCostData(self).history_branch
    if choice == "ningzhun_+1" then
      local preTargets = table.filter(room.alive_players, function(p)
        return player:inMyAttackRange(p)
      end)
      room:addPlayerMark(player, "@ningzhun_buff")
      local targetsInAttackRange = table.filter(room.alive_players, function(p)
        return player:inMyAttackRange(p)
      end)
      if table.find(targetsInAttackRange, function(p)
        return not table.contains(preTargets, p)
      end) then
        player:clearSkillHistory("shouhu")
      end
      room:setPlayerMark(player, "shouhu_targets-phase", targetsInAttackRange)
    elseif choice == "ningzhun_-1" then
      room:setPlayerMark(player, "@ningzhun_buff", player:getMark("@ningzhun_buff") - 1)
    else
      local targets = room:askToChooseToMoveCardInBoard(player, {
        skill_name = skillName,
      })

      if #targets > 1 then
        room:askToMoveCardInBoard(
          player,
          {
            target_one = targets[1],
            target_two = targets[2],
            skill_name = skillName,
          }
        )
      end
    end

    local branchesChosen = table.filter({ "ningzhun_+1", "ningzhun_-1", "ningzhun_move" }, function (branch)
      return not ningzhun:withinBranchTimesLimit(player, branch)
    end)

    if #branchesChosen > 1 then
      player:clearSkillHistory(skillName)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(ningzhun.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ningzhun_used-turn")
  end,
})

ningzhun:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("@ningzhun_buff")
  end,
})

return ningzhun
