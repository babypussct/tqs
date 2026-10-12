local guansha = fk.CreateSkill {
  name = "guansha",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["guansha"] = "灌沙",
  [":guansha"] = "限定技，出牌阶段结束时，你可以将你所有的牌替换为牌堆中等量随机基本牌，本回合手牌上限+X（X为你因此得到的牌名数）。",

  ["$guansha1"] = "今趁天寒，可灌沙为城，不过达晓之功。",
  ["$guansha2"] = "如此坚壁可成，虽金汤之固，未能过也。",
}

guansha:addEffect(fk.EventPhaseEnd, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and
      player:hasSkill(guansha.name) and player:usedSkillTimes(guansha.name, Player.HistoryGame) == 0 and
      not player:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    local x = #cards
    room:shuffleTable(cards)
    local positions = {}
    local y = #room.draw_pile
    for _ = 1, x, 1 do
      table.insert(positions, math.random(y + 1))
    end
    table.sort(positions, function (a, b)
      return a > b
    end)
    local moveInfos = {}
    for i = 1, x, 1 do
      table.insert(moveInfos, {
        ids = {cards[i]},
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = guansha.name,
        drawPilePosition = positions[i],
        proposer = player,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if player.dead then return end
    cards = room:getCardsFromPileByRule(".|.|.|.|.|basic", x)
    if #cards > 0 then
      local names = {}
      for _, id in ipairs(cards) do
        table.insertIfNeed(names, Fk:getCardById(id).trueName)
      end
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, guansha.name)
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, #names)
      end
    end
  end,
})

return guansha
