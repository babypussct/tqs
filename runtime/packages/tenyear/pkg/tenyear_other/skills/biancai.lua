
local biancai = fk.CreateSkill{
  name = "biancai",
}

Fk:loadTranslationTable{
  ["biancai"] = "辨才",
  [":biancai"] = "每名角色的回合开始时，你可以进行判定并获得判定牌，若结果为：红色，你从牌堆中获得一张装备牌；黑色，你从弃牌堆中获得一张装备牌。",

  ["$biancai1"] = "	",
  ["$biancai2"] = "",
}

biancai:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(biancai.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = biancai.name,
      pattern = ".|.|^nocolor",
    }
    room:judge(judge)
    if player.dead then return end
    if judge:matchPattern() then
      local card = {}
      if judge.card.color == Card.Red then
        card = room:getCardsFromPileByRule(".|.|.|.|.|equip", 1, "drawPile")
      elseif judge.card.color == Card.Black then
        card = room:getCardsFromPileByRule(".|.|.|.|.|equip", 1, "discardPile")
      end
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, biancai.name, nil, false, player)
      end
    end
  end,
})

biancai:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  priority = 5,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.reason == biancai.name and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, nil, biancai.name)
  end,
})

return biancai
