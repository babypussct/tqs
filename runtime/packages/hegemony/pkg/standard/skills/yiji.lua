local yiji = fk.CreateSkill{
  name = "hs__yiji",
}

Fk:loadTranslationTable{
  ["hs__yiji"] = "遗计",
  [":hs__yiji"] = "当你受到伤害后，你可以观看牌堆顶的两张牌，然后将分配给任意角色。",

  ["$hs__yiji1"] = "也好。",
  ["$hs__yiji2"] = "罢了。",
}

yiji:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(2)
    while not player.dead do
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = #ids,
        targets = room.alive_players,
        pattern = tostring(Exppattern{ id = ids }),
        skill_name = yiji.name,
        prompt = "#yiji-give",
        cancelable = true,
        expand_pile = ids,
      })
      if #tos > 0 and #cards > 0 then
        for _, id in ipairs(cards) do
          table.removeOne(ids, id)
        end
        room:moveCardTo(cards, Card.PlayerHand, tos[1], fk.ReasonGive, yiji.name, nil, false, player)
        if #ids == 0 then break end
      else
        room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonGive, yiji.name, nil, false, player)
        return
      end
    end
  end,
})

return yiji
