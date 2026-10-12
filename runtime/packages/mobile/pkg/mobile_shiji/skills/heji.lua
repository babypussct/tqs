local heji = fk.CreateSkill {
  name = "heji",
}

Fk:loadTranslationTable{
  ["heji"] = "合击",
  [":heji"] = "当一名角色使用以唯一其他角色为目标的【决斗】或红色【杀】结算后，你可以从手牌中对相同目标使用一张无距离次数限制的"..
  "【杀】或【决斗】。若你使用的不为转化牌，你使用此牌时随机获得一张红色牌。",

  ["#heji-use"] = "合击：你可以对 %dest 使用一张手牌中的【杀】或者【决斗】",

  ["$heji1"] = "你我合势而击之，区区贼寇岂会费力？",
  ["$heji2"] = "伯符！今日之战，务必全力攻之！",
}

heji:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(heji.name) and #player:getHandlyIds() > 0 and
      (data.card.trueName == "duel" or (data.card.trueName == "slash" and data.card.color == Card.Red)) and
      data:isOnlyTarget(data.tos[1]) and data.tos[1] ~= player and not data.tos[1].dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = heji.name,
      pattern = "slash,duel",
      prompt = "#heji-use::"..data.tos[1].id,
      extra_data = {
        must_targets = {data.tos[1].id},
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      if not use.card:isConverted() then
        use.extra_data = {heji = player.id}
      end
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})
heji:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.heji == player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|heart,diamond", 1)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, heji.name)
    end
  end,
})

return heji
