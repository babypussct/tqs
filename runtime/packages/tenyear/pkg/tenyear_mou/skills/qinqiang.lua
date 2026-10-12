local qinqiang = fk.CreateSkill {
  name = "qinqiang",
  max_branches_use_time = {
    ["damage"] = {
      [Player.HistoryTurn] = 1
    },
    ["draw"] = {
      [Player.HistoryTurn] = 1
    },
  },
}

Fk:loadTranslationTable {
  ["qinqiang"] = "勤强",
  [":qinqiang"] = "每回合每项限一次，你使用手牌时，你可以选择一项：1.令此牌伤害+X；2.摸X张牌（X为你本回合此前与此牌连续使用同颜色的牌数）。",

  ["#qinqiang-choice"] = "勤强：你可以选择一项",
  ["qinqiang_damage"] = "此牌伤害+%arg",
  ["qinqiang_draw"] = "摸%arg张牌",

  ["$qinqiang1"] = "江中鱼蟹，不食魏卒血肉久矣！",
  ["$qinqiang2"] = "今日多流一斗汗，他日少溅三升血！",
}

qinqiang:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qinqiang.name) and
        data:isUsingHandcard(player) and player:usedSkillTimes(qinqiang.name, Player.HistoryTurn) < 2 then
      local n = 0
      player.room.logic:getEventsByRule(GameEvent.UseCard, 999, function(e)
        local use = e.data
        if use.from == player then
          if use.card.color == data.card.color then
            n = n + 1
          else
            return true
          end
        end
      end, nil, Player.HistoryTurn)
      n = n - 1
      if n > 0 then
        if data.card.is_damage_card then
          return true
        else
          return qinqiang:withinBranchTimesLimit(player, "draw", Player.HistoryTurn)
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getEventsByRule(GameEvent.UseCard, 999, function(e)
      local use = e.data
      if use.from == player then
        if use.card.color == data.card.color then
          n = n + 1
        else
          return true
        end
      end
    end, nil, Player.HistoryTurn)
    n = n - 1
    local all_choices = { "qinqiang_damage:::" .. n, "qinqiang_draw:::" .. n }
    local choices = table.simpleClone(all_choices)
    if not qinqiang:withinBranchTimesLimit(player, "draw", Player.HistoryTurn) then
      table.remove(choices, 2)
    end
    if not data.card.is_damage_card or not qinqiang:withinBranchTimesLimit(player, "damage", Player.HistoryTurn) then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(player, {
      skill_name = qinqiang.name,
      prompt = "#qinqiang-choice",
      choices = choices,
      all_choices = all_choices,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice, n = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    local n = event:getCostData(self).n
    if choice:startsWith("qinqiang_damage") then
      player:addSkillBranchUseHistory(qinqiang.name, "damage", 1)
      data.additionalDamage = (data.additionalDamage or 0) + n
    else
      player:addSkillBranchUseHistory(qinqiang.name, "draw", 1)
      player:drawCards(n, qinqiang.name)
    end
  end,
})

return qinqiang
