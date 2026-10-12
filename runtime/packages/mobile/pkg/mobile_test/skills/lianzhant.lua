local lianzhan = fk.CreateSkill {
  name = "lianzhant",
}

Fk:loadTranslationTable{
  ["lianzhant"] = "连斩",
  [":lianzhant"] = "当你使用指定唯一目标的有点数的【杀】结算结束后，你可以对其使用一张无距离次数限制且点数更大的【杀】并摸一张牌。",

  ["#lianzhant-slash"] = "连斩：你可对 %dest 使用一张点数大于%arg的【杀】并摸一张牌",

  ["$lianzhant1"] = "城门已开，还不杀入城去！",
  ["$lianzhant2"] = "哈哈哈哈，连斩两员，痛快痛快！",
}

lianzhan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      data.card.number > 0 and
      player:hasSkill(lianzhan.name) and
      data:isOnlyTarget(data.tos[1]) and
      data.tos[1]:isAlive()
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(
      player,
      {
        pattern = "slash|" .. (data.card.number + 1) .. "~99",
        skill_name = lianzhan.name,
        prompt = "#lianzhant-slash::" .. data.tos[1].id .. ":" .. data.card.number,
        extra_data = {
          must_targets = { data.tos[1].id },
          exclusive_targets = { data.tos[1].id },
          bypass_distances = true,
          bypass_times = true,
        }
      }
    )

    if use then
      event:setCostData(self, { use = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).use
    use.extra_data = use.extra_data or {}
    use.extra_data.lianzhantUser = player
    player.room:useCard(use)
  end,
})

lianzhan:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:isAlive() and player == (data.extra_data or {}).lianzhantUser
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, lianzhan.name)
  end,
})

return lianzhan
