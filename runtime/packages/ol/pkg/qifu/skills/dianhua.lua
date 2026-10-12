local dianhua = fk.CreateSkill {
  name = "ol__dianhua",
}

Fk:loadTranslationTable{
  ["ol__dianhua"] = "点化",
  [":ol__dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你〖法箓〗的标记数）。然后将这些牌以任意顺序放回牌堆顶或牌堆底。",

  ["$ol__dianhua1"] = "道法自然，点化陈腐以为新。",
  ["$ol__dianhua2"] = "遵方点化，化险为夷。",
}

dianhua:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dianhua.name) and
      (player.phase == Player.Start or player.phase == Player.Finish) and
      table.find({"spade", "club", "heart", "diamond"}, function(suit)
        return player:getMark("@@ol__falu_"..suit) > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter({"spade", "club", "heart", "diamond"}, function(suit)
      return player:getMark("@@ol__falu_"..suit) > 0
    end)
    room:askToGuanxing(player, {
      cards = room:getNCards(n),
    })
  end,
})

return dianhua
