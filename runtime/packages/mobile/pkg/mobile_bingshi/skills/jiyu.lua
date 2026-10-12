local jiyu = fk.CreateSkill {
  name = "jiyul",
}

Fk:loadTranslationTable{
  ["jiyul"] = "急御",
  [":jiyul"] = "出牌阶段限一次，你可以弃置一张手牌，从牌堆或弃牌堆随机获得与此牌类别不同的牌各一张；每阶段限两次，若你使用了所有因此获得的牌，"..
  "此技能视为未发动过。",

  ["#jiyul"] = "急御：弃置一张手牌，随机获得与此牌类别不同的牌各一张",
  ["@@jiyul-phase"] = "急御",

  ["$jiyul1"] = "三军既出，营为首务，安可不城以御乎？",
  ["$jiyul2"] = "丞相英明一世，岂为此事所迷？",
  ["$jiyul3"] = "丞相今与贼战，当即筑营寨，以御敌变也。",
}

jiyu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#jiyul",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local cardType = Fk:getCardById(effect.cards[1]):getTypeString()
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local types = { "basic", "trick", "equip" }
    table.removeOne(types, cardType)
    local cards = {}
    for _, type in ipairs(types) do
      for _, pile in ipairs({ "drawPile", "discardPile" }) do
        local cardIds = room:getCardsFromPileByRule(".|.|.|.|.|" .. type, 1, pile)
        if #cardIds > 0 then
          table.insertTable(cards, cardIds)
          break
        end
      end
    end
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, jiyu.name, "@@jiyul-phase")
    end
  end,
})

jiyu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jiyu.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local loseByUse = false
    local loseByOtherReason = false
    local card
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          card = Fk:getCardById(info.cardId)
          if card:getMark("@@jiyul-phase") ~= 0 then
            room:setCardMark(card, "@@jiyul-phase", 0)
            if move.moveReason == fk.ReasonUse then
              loseByUse = true
            else
              loseByOtherReason = true
            end
          end
        end
      end
    end
    if loseByOtherReason then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@jiyul-phase", 0)
      end
    elseif loseByUse and table.every(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@jiyul-phase") == 0
    end) and player:getMark("jiyul_reset-turn") < 2 then
      player:broadcastSkillInvoke(jiyu.name, 3)
      room:addPlayerMark(player, "jiyul_reset-turn", 1)
      player:setSkillUseHistory(jiyu.name, 0, Player.HistoryPhase)
    end
  end,
})

jiyu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@jiyul-phase", 0)
  end
  room:setPlayerMark(player, "jiyul_reset-turn", 0)
end)

return jiyu
