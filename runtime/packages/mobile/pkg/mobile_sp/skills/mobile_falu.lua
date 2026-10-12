local mobileFalu = fk.CreateSkill {
  name = "mobile__falu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__falu"] = "法箓",
  [":mobile__falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>"..
  "♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br>"..
  "<font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",

  ["@@mobile__faluspade"] = "♠紫微",
  ["@@mobile__faluclub"] = "♣后土",
  ["@@mobile__faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@mobile__faludiamond"] = "<font color='red'>♦</font>勾陈",

  ["$mobile__falu1"] = "修撰法箓，以继黄老。",
  ["$mobile__falu2"] = "化无为有，以有载无。",
}

mobileFalu:addEffect(fk.GameStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mobileFalu.name)
  end,
  on_use = function(self, event, target, player, data)
    local suits = { "spade", "club", "heart", "diamond" }
    for i = 1, 4, 1 do
      player.room:addPlayerMark(player, "@@mobile__falu" .. suits[i], 1)
    end
  end,
})

mobileFalu:addEffect(fk.AfterCardsMove, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(mobileFalu.name) then
      return false
    end

    for _, move in ipairs(data) do
      if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
        local costData = {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            local suit = Fk:getCardById(info.cardId):getSuitString()
            if player:getMark("@@mobile__falu" .. suit) == 0 then
              table.insertIfNeed(costData, suit)
            end
          end
        end
        if #costData > 0 then
          event:setCostData(self, costData)
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, suit in ipairs(event:getCostData(self)) do
      player.room:addPlayerMark(player, "@@mobile__falu" .. suit, 1)
    end
  end,
})

mobileFalu:addLoseEffect(function (self, player)
  local suits = { "spade", "club", "heart", "diamond" }
  for i = 1, 4, 1 do
    player.room:setPlayerMark(player, "@@mobile__falu" .. suits[i], 0)
  end
end)

return mobileFalu
