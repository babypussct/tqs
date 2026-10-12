
local pingkou = fk.CreateSkill {
  name = "ol_ex__pingkou",
  max_branches_use_time = function(self, player)
    local ret = {}
    for _, to in ipairs(Fk:currentRoom().players) do
      ret[tostring(to.id)] = {
        [Player.HistoryGame] = 1,
      }
    end
    return ret
  end,
}

Fk:loadTranslationTable{
  ["ol_ex__pingkou"] = "平寇",
  [":ol_ex__pingkou"] = "回合结束时，你可以对至多X名其他角色各造成1点伤害（X为你本回合跳过的阶段数）。"..
  "你每以此法造成一次伤害，摸一张牌（每名角色限一次）。",

  ["#ol_ex__pingkou-choose"] = "平寇：你可以对至多%arg名角色各造成1点伤害",
  ["ol_ex__pingkou_draw"] = "未选择过",

  ["$ol_ex__pingkou1"] = "",
  ["$ol_ex__pingkou2"] = "",
}

Fk:addTargetTip{
  name = pingkou.name,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if selectable and pingkou:withinBranchTimesLimit(player, tostring(to_select.id), Player.HistoryGame) then
      return "ol_ex__pingkou_draw"
    end
  end,
}

pingkou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pingkou.name) and
      table.find(data.phase_table, function(phase)
        return phase.who == player and phase.skipped
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(data.phase_table, function(phase)
      return phase.who == player and phase.skipped
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      targets = room:getOtherPlayers(player, false),
      skill_name = pingkou.name,
      prompt = "#ol_ex__pingkou-choose:::" .. n,
      cancelable = true,
      target_tip_name = pingkou.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos or {}
    for _, p in ipairs(tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = pingkou.name,
        }
        if pingkou:withinBranchTimesLimit(player, tostring(p.id), Player.HistoryGame) and not player.dead then
          player:addSkillBranchUseHistory(pingkou.name, tostring(p.id), Player.HistoryGame)
          player:drawCards(1, pingkou.name)
        end
      end
    end
  end,
})

return pingkou
