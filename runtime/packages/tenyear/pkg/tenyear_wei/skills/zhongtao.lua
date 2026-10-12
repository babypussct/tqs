local zhongtao = fk.CreateSkill {
  name = "ty__zhongtao",
}

Fk:loadTranslationTable{
  ["ty__zhongtao"] = "众讨",
  [":ty__zhongtao"] = "出牌阶段限一次，你可以选择X种花色（X为你已损失的体力值+1，且至多为4），" ..
  "随机从场上、弃牌堆或牌堆获得你选择花色的牌各一张。若如此做，你使用三种类别的牌后，此技能视为未发动过。",

  ["#ty__zhongtao"] = "众讨：请选择%arg种花色",

  ["$ty__zhongtao1"] = "凉州男儿，可愿随我再破千军！",
  ["$ty__zhongtao2"] = "你我勠力讨贼，何人可堪一战！",
}

zhongtao:addEffect("active", {
  anim_type = "drawcard",
  prompt = function(self, player)
    return "#ty__zhongtao:::" .. math.min(4, 1 + player:getLostHp())
  end,
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.CheckBox {
      choices = { "heart", "diamond", "spade", "club" },
      min_num = math.min(4, 1 + player:getLostHp()),
      max_num = math.min(4, 1 + player:getLostHp()),
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  feasible = function(self, player, selected, selected_cards, card)
    return type(self.interaction.data) == "table" and #self.interaction.data > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = self.interaction.data

    local cardsOnField = {}
    local suitsOnField = {}
    for _, p in ipairs(room.alive_players) do
      local cards = p:getCardIds("ej")
      for _, id in ipairs(cards) do
        local suit = Fk:getCardById(id):getSuitString()
        if table.contains(choices, suit) then
          cardsOnField[suit] = cardsOnField[suit] or {}
          table.insert(cardsOnField[suit], id)
          table.insertIfNeed(suitsOnField, suit)
        end
      end
    end

    local moves = {}

    if next(cardsOnField) then
      local randomSuit = room:tableRandomPick(suitsOnField)
      table.removeOne(choices, randomSuit)
      local ids = room:tableRandomPick(cardsOnField[randomSuit], 1)
      table.removeOne(cardsOnField, ids[1])
      table.insert(moves, {
        ids = ids,
        from = room:getCardOwner(ids[1]),
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        skillName = zhongtao.name,
        proposer = player,
        moveVisible = true,
      })
    end

    for _, suit in ipairs(choices) do
      local ids = room:getCardsFromPileByRule(".|.|" .. suit, 1, "discardPile")
      if #ids > 0 then
        table.insert(moves, {
          ids = ids,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          skillName = zhongtao.name,
          proposer = player,
          moveVisible = true,
        })
      else
        ids = room:getCardsFromPileByRule(".|.|" .. suit)
        if #ids > 0 then
          table.insert(moves, {
            ids = ids,
            to = player,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            skillName = zhongtao.name,
            proposer = player,
            moveVisible = false,
          })
        else
          ids = cardsOnField[suit] or {}
          if #ids > 0 then
            table.insert(moves, {
              ids = ids,
              from = room:getCardOwner(ids[1]),
              to = player,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonPrey,
              skillName = zhongtao.name,
              proposer = player,
              moveVisible = true,
            })
          end
        end
      end
    end

    if next(moves) then
      room:moveCards(table.unpack(moves))
    end
  end,
})

zhongtao:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(zhongtao.name, true) and
      player.phase == Player.Play and
      not table.contains(player:getTableMark("zhongtao_record-phase"), data.card.type)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "zhongtao_record-phase", data.card.type)

    if #player:getMark("zhongtao_record-phase") > 2 then
      room:setPlayerMark(player, "zhongtao_record-phase", 0)
      if player:usedSkillTimes(zhongtao.name) > 0 then
        player:clearSkillHistory(zhongtao.name)
      end
    end
  end,
})

return zhongtao
