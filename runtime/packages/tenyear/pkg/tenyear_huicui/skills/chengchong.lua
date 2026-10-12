local chengchong = fk.CreateSkill {
  name = "chengchong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chengchong"] = "承宠",
  [":chengchong"] = "锁定技，当你不因此技能而得到牌后，若你手牌区里的除这些牌以外的牌中的红色牌数不小于黑色牌数，你摸一张牌。",

  ["$chengchong1"] = "",
  ["$chengchong2"] = "",
}

chengchong:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chengchong.name) then
      local handCards = player:getCardIds("h")
      local isGainOtherCard = false
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.skillName ~= chengchong.name then
          isGainOtherCard = true
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(handCards, info.cardId)
          end
        end
      end
      if not isGainOtherCard then
        return false
      end
      local colorDiff = 0
      for _, cardId in ipairs(handCards) do
        local card = Fk:getCardById(cardId)
        if card.color == Card.Red then
          colorDiff = colorDiff + 1
        elseif card.color == Card.Black then
          colorDiff = colorDiff - 1
        end
      end
      return colorDiff >= 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, chengchong.name)
  end,
})

return chengchong
