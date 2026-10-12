local xianshuai = fk.CreateSkill {
  name = "m_shi__xianshuai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_shi__xianshuai"] = "先率",
  [":m_shi__xianshuai"] = "锁定技，你于回合内使用手牌中每个花色的首张牌不计入次数限制且无次数限制。",

  ["@m_shi__xianshuai-turn"] = "先率",

  ["$m_shi__xianshuai1"] = "吾不为陛下分忧，谁为陛下分忧？",
  ["$m_shi__xianshuai2"] = "臣即率兵马、征伐曹魏。",
}

xianshuai:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianshuai.name) and
      player.room:getCurrent() == player and
      #Card:getIdList(data.card) == 1 and table.contains(player:getCardIds("h"), Card:getIdList(data.card)[1]) and
      not table.contains(player:getTableMark("@m_shi__xianshuai-turn"), data.card:getSuitString(true)) and
      data.card.suit ~= Card.NoSuit
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "@m_shi__xianshuai-turn", data.card:getSuitString(true))
    data.extraUse = true
  end,
})

xianshuai:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return player:hasSkill(xianshuai.name) and Fk:currentRoom():getCurrent() == player and
      card and #Card:getIdList(card) == 1 and table.contains(player:getCardIds("h"), Card:getIdList(card)[1]) and
      not table.contains(player:getTableMark("@m_shi__xianshuai-turn"), card:getSuitString(true)) and
      card.suit ~= Card.NoSuit
  end,
})

xianshuai:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    if room:getCurrent() == player then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player and #Card:getIdList(use.card) == 1 and use.card.suit ~= Card.NoSuit then
          e:searchEvents(GameEvent.MoveCards, 1, function (e2)
            for _, move in ipairs(e2.data) do
              if move.from == player and move.moveReason == fk.ReasonUse then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.PlayerHand and info.cardId == Card:getIdList(use.card)[1] then
                    room:addTableMarkIfNeed(player, "@m_shi__xianshuai-turn", use.card:getSuitString(true))
                  end
                end
              end
            end
          end)
        end
      end, Player.HistoryTurn)
    end
  end
end)

return xianshuai
