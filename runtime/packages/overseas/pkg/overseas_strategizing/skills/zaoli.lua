local zaoli = fk.CreateSkill {
  name = "os__zaoli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__zaoli"] = "躁厉",
  [":os__zaoli"] = "锁定技，出牌阶段，你只能使用或打出本回合获得的手牌。出牌阶段开始时，你弃置你所有装备牌和任意张非装备牌，然后摸X张牌，"..
  "并从牌堆中将你弃置牌中相同子类别的装备牌置入装备区，若你以此法置入装备区的牌数大于2，你失去1点体力。（X为你以此法弃置的牌的总数）",

  ["#os__zaoli-discard"] = "躁厉：弃置任意张手牌和所有装备牌，摸等量张牌",
  ["@@os__zaoli-inhand-turn"] = "躁厉",

  ["$os__zaoli1"] = "喜怒不形于色，诈伪要明之徒。",
  ["$os__zaoli2"] = "摇舌鼓唇，竖子是之也！",
}

zaoli:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zaoli.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local subTypes = {}
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      table.insertIfNeed(subTypes, card:getSubtypeString())
    end
    table.insertTable(cards, room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = zaoli.name,
      pattern = ".|.|.|.|.|^equip",
      prompt = "#os__zaoli-discard",
      cancelable = true,
      skip = true,
    }))
    if #cards == 0 then return end
    room:throwCard(cards, zaoli.name, player, player)
    if player.dead then return end
    player:drawCards(#cards, zaoli.name)
    if player.dead then return end
    local cids = {}
    for _, subType in ipairs(subTypes) do
      local equips = room:getCardsFromPileByRule(".|.|.|.|.|" .. subType)
      if #equips > 0 and player:canMoveCardIntoEquip(equips[1], false) then
        table.insert(cids, equips[1])
      end
    end
    if #cids > 0 then
      room:moveCardIntoEquip(player, cids, zaoli.name, false, player)
      if #cids > 2 and not player.dead then
        room:loseHp(player, 1, zaoli.name)
      end
    end
  end,
})

zaoli:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    if room.current == player and not player:isKongcheng() then
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.toArea == Player.Hand then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player:getCardIds("h"), info.cardId) then
                room:setCardMark(Fk:getCardById(info.cardId), "@@os__zaoli-inhand-turn", 1)
              end
            end
          end
        end
      end, Player.HistoryTurn)
    end
  end
end)

zaoli:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(zaoli.name, true) and player.room.current == player then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@os__zaoli-inhand-turn", 1)
          end
        end
      end
    end
  end,
})

zaoli:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:hasSkill(zaoli.name) and player.phase == Player.Play then
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("@@os__zaoli-inhand-turn") == 0 and table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:hasSkill(zaoli.name) and player.phase == Player.Play then
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("@@os__zaoli-inhand-turn") == 0 and table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return zaoli
