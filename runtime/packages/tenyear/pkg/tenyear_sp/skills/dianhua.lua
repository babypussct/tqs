local dianhua = fk.CreateSkill {
  name = "dianhua",
  dynamic_desc = function(self, player)
    return "dianhua_inner:"..tostring(player:getMark("dianhua")+1)
  end,
}

Fk:loadTranslationTable{
  ["dianhua"] = "点化",
  [":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶1张牌，然后获得其中一张牌，其余的牌以任意顺序放回牌堆顶。",

  [":dianhua_inner"] = "准备阶段或结束阶段，你可以观看牌堆顶{1}张牌，然后获得其中一张牌，其余的牌以任意顺序放回牌堆顶。",

  ["#dianhua-arrange"] = "点化：获得其中1张牌，放回其余的牌",

  ["$dianhua1"] = "大道无形，点化无为。",
  ["$dianhua2"] = "得此点化，必得大道。",
}

dianhua:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dianhua.name) and
      (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_use = function(self, event, target, player, data)
    local skillName = dianhua.name
    local room = player.room
    local cards = room:getNCards(1 + player:getMark("dianhua"))
    room:turnOverCardsFromDrawPile(player, cards, skillName, false)
    if #cards == 1 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, skillName)
      return
    end
    local result = room:askToArrangeCards(player, {
      skill_name = skillName,
      card_map = {cards, "Top","toObtain"},
      prompt = "#dianhua-arrange",
      free_arrange = true,
      box_size = 5,
      min_limit = {0, 1},
      max_limit = {0, 1},
    })
    local moveInfos = {}
    table.insert(moveInfos, {
      ids = table.reverse(result[2]),
      to = player,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      proposer = player,
      moveVisible = false,
    })
    if #result[1] > 0 then
      table.insert(moveInfos, {
        ids = table.reverse(result[1]),
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = skillName,
        proposer = player,
        moveVisible = false,
        visiblePlayers = player,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

dianhua:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "dianhua", 0)
end)

dianhua:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return dianhua
