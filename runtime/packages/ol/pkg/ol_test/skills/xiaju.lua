
local xiaju = fk.CreateSkill {
  name = "xiaju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiaju"] = "霞举",
  [":xiaju"] = "锁定技，你每回合首次失去牌后，你获得一张未拥有花色的牌。若因此凑齐四种花色，下次此技能获得牌数+1。",

  ["$xiaju1"] = "",
  ["$xiaju2"] = "",
}

xiaju:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  priority = 1.1,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiaju.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = { "spade", "heart", "club", "diamond" }
    for _, id in ipairs(player:getCardIds("h")) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    local suit_pattern = table.concat(suits, ",")
    local cards = room:getCardsFromPileByRule(".|.|" .. suit_pattern, 1 + player:getMark(xiaju.name), "allPiles")
    if #cards > 0 then
      room:setPlayerMark(player, xiaju.name, 0)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xiaju.name, nil, false, player)
      if player:hasSkill(xiaju.name, true) then
        suits = { 1, 2, 3, 4 }
        for _, card in ipairs(player:getCardIds("h")) do
          table.removeOne(suits, Fk:getCardById(card).suit)
        end
        if #suits == 0 then
          room:addPlayerMark(player, xiaju.name, 1)
        end
      end
    end
  end,
})

return xiaju
