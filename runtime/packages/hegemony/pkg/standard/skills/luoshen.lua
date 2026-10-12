local luoshen = fk.CreateSkill{
  name = "hs__luoshen",
}

Fk:loadTranslationTable{
  ["hs__luoshen"] = "洛神",
  [":hs__luoshen"] = "准备阶段，你可以进行判定，你可以重复此流程，直到判定结果为红色，然后你获得所有黑色的判定牌。",

  ["$hs__luoshen1"] = "髣髴兮若轻云之蔽月。",
  ["$hs__luoshen2"] = "飘飖兮若流风之回雪。",
}

luoshen:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(luoshen.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    while true do
      local judge = {
        who = player,
        reason = luoshen.name,
        pattern = ".|.|spade,club",
        skipDrop = true,
      }
      room:judge(judge)
      if judge.card then
        if judge:matchPattern() then
          table.insert(cards, judge.card)
        elseif room:getCardArea(judge.card) == Card.Processing then
          room:moveCardTo(judge.card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, luoshen.name, nil, true, player)
        end
        if not judge:matchPattern() or player.dead or
          not room:askToSkillInvoke(player, {
            skill_name = luoshen.name,
          }) then
          break
        end
      end
    end
    cards = table.filter(cards, function(c)
      return room:getCardArea(c) == Card.Processing
    end)
    if #cards > 0 then
      if not player.dead then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, luoshen.name, nil, true, player)
      else
        room:cleanProcessingArea(cards)
      end
    end
  end,
})

local AI = Fk.Ltk.AI
luoshen:addAI(AI.reuse("luoshen", AI.InvokeStrategy))

return luoshen
