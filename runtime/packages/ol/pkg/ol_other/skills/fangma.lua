
local fangma = fk.CreateSkill{
  name = "fangma",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fangma"] = "放马",
  [":fangma"] = "锁定技，你不能整理手牌。每轮开始时，将【赤兔】置入你的手牌最左侧，且你不能使用、打出或弃置之。"..
  "若你手中在【赤兔】左侧的牌：较多，你的【杀】无次数限制；较少，你的【杀】需要两张【闪】才能抵消。",

  ["$fangma1"] = "姑奶奶在此，尽管放马过来！",
  ["$fangma2"] = "咱可是要赢得天下的战马！",
}

fangma:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fangma.name) and
      not table.contains(player:getCardIds("h"), player:getMark(fangma.name))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(player:getMark(fangma.name), Card.PlayerHand, player, fk.ReasonPrey, fangma.name, nil, true, player)
    local cards = player.player_cards[Player.Hand]
    if table.contains(cards, player:getMark(fangma.name)) then
      table.removeOne(cards, player:getMark(fangma.name))
      table.insert(cards, 1, player:getMark(fangma.name))
      player.player_cards[Player.Hand] = cards
      room:syncPlayerClientCards(player)
    end
  end,
})

fangma:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return player:hasSkill(fangma.name) and card and card.id == player:getMark(fangma.name)
  end,
  prohibit_response = function (self, player, card)
    return player:hasSkill(fangma.name) and card and card.id == player:getMark(fangma.name)
  end,
  prohibit_discard = function (self, player, card)
    return player:hasSkill(fangma.name) and card and card.id == player:getMark(fangma.name)
  end,
})

fangma:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    if player:hasSkill(fangma.name) and card and card.trueName == "slash" then
      local left, right, tmp = 0, 0, false
      for _, id in ipairs(player:getCardIds("h")) do
        if id == player:getMark(fangma.name) then
          tmp = true
        else
          if not tmp then
            left = left + 1
          else
            right = right + 1
          end
        end
      end
      return left > right
    end
  end,
})

fangma:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fangma.name) and
      data.card.trueName == "slash" then
      local left, right, tmp = 0, 0, false
      for _, id in ipairs(player:getCardIds("h")) do
        if id == player:getMark(fangma.name) then
          tmp = true
        else
          if not tmp then
            left = left + 1
          else
            right = right + 1
          end
        end
      end
      return left < right
    end
  end,
  on_use = function (self, event, target, player, data)
    data:setResponseTimes(2, data.to)
  end,
})

fangma:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  room:banSortingHandcards(player)
  local card = room:getCardsFromPileByRule("chitu", 1, "allPiles")
  if #card == 0 then
    card = { room:printCard("chitu", Card.Heart, 5).id }
  end
  room:setPlayerMark(player, fangma.name, card[1])
end)

fangma:addLoseEffect(function (self, player, is_death)
  player.room:unbanSortingHandcards(player)
end)

return fangma
