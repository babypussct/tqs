local jibian = fk.CreateSkill {
  name = "jibian",
}

Fk:loadTranslationTable{
  ["jibian"] = "急辩",
  [":jibian"] = "当你拼点时，你可以摸至多三张牌，若如此做，你本次拼点牌点数-X（X为你本次摸牌数）。",

  ["#jibian-invoke"] = "急辩：摸至多三张牌，本次拼点减等量点数",

  ["$jibian1"] = "且以某三寸之舌，搅动万顷之水！",
  ["$jibian2"] = "言出我口，入君耳，上不至天，下不至地。",
}

jibian:addEffect(fk.StartPindian, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jibian.name) then
      if player == data.from then
        return true
      else
        return table.contains(data.tos, player)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = room:askToNumber(player, {
      skill_name = jibian.name,
      prompt = "#jibian-invoke",
      min = 1,
      max = 3,
      cancelable = true,
    })
    if n then
      event:setCostData(self, { choice = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = event:getCostData(self).choice
    player:drawCards(n, jibian.name)
    if not player.dead then
      data.extra_data = data.extra_data or {}
      data.extra_data.jibian = data.extra_data.jibian or {}
      data.extra_data.jibian[player] = n
    end
  end,
})

jibian:addEffect(fk.PindianCardsDisplayed, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.jibian and data.extra_data.jibian[player]
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:changePindianNumber(data, player, -data.extra_data.jibian[player], jibian.name)
  end,
})

return jibian
