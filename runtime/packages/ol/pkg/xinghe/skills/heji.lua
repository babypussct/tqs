local ol__heji = fk.CreateSkill {
  name = "ol__heji",
}

Fk:loadTranslationTable {
  ["ol__heji"] = "合击",
  [":ol__heji"] = "一名角色使用仅指定唯一目标的【决斗】或红色【杀】后，你可对同目标使用一张" ..
      "【杀】或【决斗】。若你以此法使用的不为转化牌，你随机获得一张红色牌。",

  ["#ol__heji-use"] = "合击：你可以对 %dest 使用一张【杀】或者【决斗】",

  ["$ol__heji1"] = "你我合势而击之，区区贼寇岂会费力？",
  ["$ol__heji2"] = "伯符！今日之战，务必全力攻之！",
}

ol__heji:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ol__heji.name) and #player:getHandlyIds() > 0 and
        (data.card.trueName == "duel" or (data.card.trueName == "slash" and data.card.color == Card.Red)) and
        data:isOnlyTarget(data.tos[1]) and data.tos[1] ~= player and not data.tos[1].dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = ol__heji.name,
      pattern = "slash,duel",
      prompt = "#ol__heji-use::" .. data.tos[1].id,
      extra_data = {
        must_targets = { data.tos[1].id },
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      if not use.card:isConverted() then
        use.extra_data = { ol__heji = player.id }
      end
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})
ol__heji:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ol__heji == player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|heart,diamond", 1)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, ol__heji.name)
    end
  end,
})

return ol__heji
