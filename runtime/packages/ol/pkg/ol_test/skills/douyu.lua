local douyu = fk.CreateSkill{
  name = "douyu",
}

Fk:loadTranslationTable{
  ["douyu"] = "斗誉",
  [":douyu"] = "你的拼点牌亮出前，你可以与对方交换拼点牌，若你赢，你摸两张牌。",

  ["#douyu-invoke"] = "斗誉：是否与 %dest 交换拼点牌？若你赢，你摸两张牌",

  ["$douyu1"] = "",
  ["$douyu2"] = "",
}

douyu:addEffect(fk.PindianCardsDisplaying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(douyu.name) and data.fromCard then
      if data.from == player and #data.tos == 1 and data.results[data.tos[1]].toCard then
        return true
      elseif data.results[player] and data.results[player].toCard then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = data.from
    if data.from == player then
      to = data.tos[1]
    end
    if room:askToSkillInvoke(player, {
      skill_name = douyu.name,
      prompt = "#douyu-invoke::"..to.id,
    }) then
      event:setCostData(self, { tos = { to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.douyu = data.extra_data.douyu or {}
    table.insert(data.extra_data.douyu, player)
    if data.from == player then
      data.fromCard, data.results[data.tos[1]].toCard = data.results[data.tos[1]].toCard, data.fromCard
    else
      data.fromCard, data.results[player].toCard = data.results[player].toCard, data.fromCard
    end
  end,
})

douyu:addEffect(fk.PindianFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.douyu and table.contains(data.extra_data.douyu, player) and not player.dead then
      if data.from == player then
        return data.results[data.tos[1]].winner == player
      else
        return data.results[player].winner == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, douyu.name)
  end,
})

return douyu
