local handan = fk.CreateSkill {
  name = "peixiu_handan",
}

Fk:loadTranslationTable {
  ["peixiu_handan"] = "邯郸",
  [":peixiu_handan"] = "你使用一张非伤害普通锦囊牌后，你令一名角色获得此牌（每回合限一次）。",

  ["#peixiu_handan-choose"] = "邯郸：选择一名角色，令其获得%arg",
}

handan:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(handan.name) and
      player:usedSkillTimes(handan.name, Player.HistoryTurn) == 0 and
      data.card.type == Card.TypeTrick and not data.card.is_damage_card and
      table.contains({ Card.Processing, Card.PlayerJudge }, player.room:getCardArea(data.card))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = handan.name,
      prompt = "#peixiu_handan-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(data.card, Card.PlayerHand, event:getCostData(self).tos[1], fk.ReasonGive, handan.name, nil, false, player)
  end,
})

return handan
