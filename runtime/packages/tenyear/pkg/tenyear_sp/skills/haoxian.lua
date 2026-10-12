local haoxian = fk.CreateSkill {
  name = "haoxian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["haoxian"] = "豪贤",
  [":haoxian"] = "限定技，出牌阶段，你可以将弃牌堆中所有点数为3的牌洗入牌库，然后获得其他角色手牌中点数为3的牌。",

  ["#haoxian"] = "豪贤：将弃牌堆中所有点数为3的牌洗入牌库，获得其他角色手牌中点数为3的牌",

  ["$haoxian1"] = "某敬的是天下好汉，护的是黎民苍生！",
  ["$haoxian2"] = "天下事，有理无理，先打过再说！",
}

haoxian:addEffect("active", {
  prompt = "#haoxian",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local skillName = haoxian.name
    local cards = table.filter(room.discard_pile, function(id)
      return Fk:getCardById(id).number == 3
    end)
    local x = #cards
    if x > 0 then
      table.shuffle(cards)
      local positions = {}
      local y = #room.draw_pile
      for _ = 1, x, 1 do
        table.insert(positions, math.random(y+1))
      end
      table.sort(positions, function(a, b) return a > b end)
      local moveInfos = {}
      for i = 1, x, 1 do
        table.insert(moveInfos, {
          ids = { cards[i] },
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = skillName,
          drawPilePosition = positions[i],
        })
      end
      room:moveCards(table.unpack(moveInfos))
      if player.dead then return false end
    end
    cards = {}
    --依次获得每名其他角色手牌区里所有点数为3的牌
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        cards = table.filter(p:getCardIds("h"), function(id)
          return Fk:getCardById(id).number == 3
        end)
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, skillName, nil, false, player)
          if player.dead then break end
        end
      end
    end
  end,
}, { check_skill_limit = true })

return haoxian
