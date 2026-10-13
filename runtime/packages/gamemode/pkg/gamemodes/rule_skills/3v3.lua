local rule = fk.CreateSkill {
  name = "#m_3v3_rule&",
}

--暖色方主帅初始手牌数+1
rule:addEffect(fk.DrawInitialCards, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.seat == 5
  end,
  on_refresh = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

--AOE自选结算方向
rule:addEffect(fk.PreCardUse, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.multiple_targets and data.card.skill.min_target_num == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"clockwise", "anticlockwise"},
      skill_name = "game_rule",
      prompt = "#m_3v3_aoe-choice:::"..data.card:toLogString(),
    })
    if choice == "clockwise" then
      data.extra_data = data.extra_data or {}
      data.extra_data.m_3v3_reverse = true
    end
  end,
})
rule:addEffect(fk.BeforeCardUseEffect, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return player.seat == 1 and
      data.extra_data and data.extra_data.m_3v3_reverse and #data.tos > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local new_tos = {}
    local players = {room.current}
    table.insertTable(players, table.reverse(room:getOtherPlayers(room.current)))
    for _, p in ipairs(players) do
      for _, to in ipairs(data.tos) do
        if to == p then
          table.insert(new_tos, p)
          break
        end
      end
    end
    data.tos = new_tos
  end,
})

--无中生有多摸一张牌（eg.孙乾转化出的原版无中），按理来说应该改卡牌的skill
rule:addEffect(fk.BeforeDrawCard, {
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.skillName == "ex_nihilo_skill" and
      #player:getFriends() < #player:getEnemies()
  end,
  on_refresh = function(self, event, target, player, data)
    data.skillName = "v33__ex_nihilo_skill"
    data.num = data.num + 1
  end,
})

return rule
