local kuangxiang = fk.CreateSkill {
  name = "mobile__kuangxiang",
}

Fk:loadTranslationTable{
  ["mobile__kuangxiang"] = "匡襄",
  [":mobile__kuangxiang"] = "出牌阶段限一次，你可以与一名手牌数不大于你的其他角色交换手牌，直到你下个出牌阶段开始，"..
  "当你或其失去所有因此获得的手牌后，你可以执行一次〖蓄业〗的效果。",

  ["#mobile__kuangxiang"] = "匡襄：你可以与一名手牌数不大于你的角色交换手牌",
  ["@@mobile__kuangxiang-inhand"] = "匡襄",
  ["#mobile__kuangxiang-invoke"] = "匡襄：是否执行一次“蓄业”效果摸两张牌？",

  ["$mobile__kuangxiang1"] = "吾与益州有通家之好，安忍其诸孙受害。",
  ["$mobile__kuangxiang2"] = "匡君辅政，丈夫之任也。",
  ["$mobile__kuangxiang3"] = "伐鲁之事，吾可为君之助力。",
}

kuangxiang:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__kuangxiang",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuangxiang.name, Player.HistoryPhase) == 0 and
      not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and player ~= to_select and to_select:getHandcardNum() <= player:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards1, cards2 = table.simpleClone(player:getCardIds("h")), table.simpleClone(target:getCardIds("h"))
    local moveInfos = {}
    if not player:isKongcheng() then
      table.insert(moveInfos, {
        from = player,
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player,
        skillName = kuangxiang.name,
        moveVisible = false,
      })
    end
    if not target:isKongcheng() then
      table.insert(moveInfos, {
        from = target,
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player,
        skillName = kuangxiang.name,
        moveVisible = false,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
    moveInfos = {}
    if not target.dead then
      local to_ex_cards = table.filter(cards1, function (id)
        if room:getCardArea(id) == Card.Processing then
          return true
        end
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = target,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player,
          skillName = kuangxiang.name,
          moveVisible = false,
          visiblePlayers = target,
          moveMark = { "@@mobile__kuangxiang-inhand", player.id },
        })
      end
    end
    if not player.dead then
      local to_ex_cards = table.filter(cards2, function (id)
        if room:getCardArea(id) == Card.Processing then
          return true
        end
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player,
          skillName = kuangxiang.name,
          moveVisible = false,
          visiblePlayers = target,
          moveMark = { "@@mobile__kuangxiang-inhand", player.id },
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
    room:cleanProcessingArea(table.connect(cards1, cards2))
  end,
})

kuangxiang:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if card:getMark("@@mobile__kuangxiang-inhand") == player.id then
          room:setCardMark(card, "@@mobile__kuangxiang-inhand", 0)
        end
      end
    end
  end,
})

kuangxiang:addLoseEffect(function (self, player, is_death)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if card:getMark("@@mobile__kuangxiang-inhand") == player.id then
          room:setCardMark(card, "@@mobile__kuangxiang-inhand", 0)
        end
      end
    end
end)

kuangxiang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(kuangxiang.name) then
      for _, move in ipairs(data) do
        if move.from and
          not table.find(move.from:getCardIds("h"), function (id)
            return Fk:getCardById(id):getMark("@@mobile__kuangxiang-inhand") == player.id
          end) then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard:getMark("@@mobile__kuangxiang-inhand") == player.id and info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = kuangxiang.name,
      prompt = "#mobile__kuangxiang-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    Fk.skills["xuye"]:use(event, player, player, data)
  end,
})

return kuangxiang
