local miyong = fk.CreateSkill{
  name = "os__miyong",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__miyong"] = "弥勇",
  [":os__miyong"] = "限定技，出牌阶段，你可以展示手牌中的至多两张【杀】。" ..
    "当此【杀】于一回合内因首次使用、首次打出或首次弃置而进入弃牌堆时，你获得之。", -- 当限一次得了
  ["#os__miyong-active"] = "发动弥勇，展示手牌中的至多两张【杀】。<br/>" ..
    "当此【杀】于一回合内因首次使用、首次打出或首次弃置而进入弃牌堆时，你获得之",

  ["@$os__miyong"] = "弥勇",
  ["@@os__miyong"] = "弥勇",

  ["$os__miyong1"] = "虎狼之躯，百战无败！",
  ["$os__miyong2"] = "铁戟亡魂无数，血甲锋迹犹存！",
}

miyong:addEffect("active", {
  prompt = "#os__miyong-active",
  can_use = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  max_card_num = 2,
  min_card_num = 1,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    return Fk:getCardById(to_select).trueName == "slash" and table.contains(player:getCardIds(Player.Hand), to_select) and #selected < 2
  end,
  on_use = function (self, room, effect)
    local from = effect.from
    from:showCards(effect.cards)
    if from:isAlive() then
      room:setPlayerMark(from, "@$os__miyong", effect.cards)
      for _, c in ipairs(effect.cards) do
        room:setCardMark(Fk:getCardById(c), "@@os__miyong", from.id)
      end
    end
  end
})

miyong:addEffect(fk.AfterCardsMove, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("@$os__miyong") == 0 then return end
    local cards = {}
    local invoke = false
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and table.contains({fk.ReasonUse, fk.ReasonResponse, fk.ReasonDiscard}, move.moveReason) then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getMark("@$os__miyong"), info.cardId)
            and not table.contains(player:getTableMark("_os__miyong-turn")[tostring(move.moveReason)] or {}, info.cardId) then
            cards[move.moveReason] = cards[move.moveReason] or {}
            table.insert(cards[move.moveReason], info.cardId)
            invoke = true
          end
        end
      end
    end
    if invoke then
      event:setCostData(self, {cs = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cs = event:getCostData(self).cs
    local cards = {}
    -- room:notifySkillInvoked(player, self.name, "special") -- FIXME: 覆盖大招
    player:broadcastSkillInvoke(self.name)
    local record = player:getTableMark("_os__miyong-turn")
    for r, c in pairs(cs) do
      record[tostring(r)] = record[tostring(r)] or {}
      table.insertTableIfNeed(record[tostring(r)], c)
      table.insertTableIfNeed(cards, c)
    end
    room:setPlayerMark(player, "_os__miyong-turn", record)
    room:obtainCard(player, cards, true, fk.ReasonPrey, player, self.name)
  end
})

return miyong
