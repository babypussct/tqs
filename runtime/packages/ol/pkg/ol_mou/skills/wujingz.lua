local wujingz = fk.CreateSkill{
  name = "wujingz",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["wujingz"] = "武靖",
  [":wujingz"] = "锁定技，你的回合内，有牌不因使用而进入弃牌堆后，你使用的下一张牌无次数限制；"..
    "每回合首次有不为手牌的牌进入弃牌堆后，你摸一张牌。",

  ["@@wujingz-turn"] = "武靖",

  ["$wujingz1"] = "天地协力，止戈为武，九鼎合归凤云台。",
  ["$wujingz2"] = "王师北定，山河重整，万民争迎汉家来。",
}

wujingz:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(wujingz.name) then
      local effects = {}
      if room:getCurrent() == player and player:getMark("@@wujingz-turn") == 0 and
      table.find(data, function(move)
        return move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and #move.moveInfo > 0
      end) then
        table.insert(effects, "addBuff")
      end
      if player:getMark("wujingz-turn") == 0 then
        local drawCard = false
        local tablecards = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.Processing then
                table.insertIfNeed(tablecards, info.cardId)
              elseif info.fromArea ~= Card.PlayerHand then
                drawCard = true
                break
              end
            end
            if drawCard then break end
          end
        end
        if drawCard then
          table.insert(effects, "drawCard")
        elseif #tablecards > 0 then
          local s_id = room.logic:getCurrentEvent().id
          room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
            if e.id >= s_id then return false end
            for _, move in ipairs(e.data) do
              if move.toArea == Card.Processing then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea ~= Card.Processing and table.removeOne(tablecards, info.cardId) and
                    info.fromArea ~= Card.PlayerHand then
                    table.insert(effects, "drawCard")
                    return true
                  end
                end
              end
            end
            return (#tablecards == 0)
          end, 0)
        end
      end
      if #effects > 0 then
        event:setCostData(self, {choices = effects})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices
    if table.contains(choices, "addBuff") then
      room:setPlayerMark(player, "@@wujingz-turn", 1)
    end
    if table.contains(choices, "drawCard") then
      room:setPlayerMark(player, "wujingz-turn", 1)
      player:drawCards(1, wujingz.name)
    end
  end,
})

wujingz:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wujingz.name) and player:getMark("@@wujingz-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@wujingz-turn", 0)
    if not data.extraUse then
      player:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
  end,
})

wujingz:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(self) and player:getMark("@@wujingz-turn") > 0
  end,
})

wujingz:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@@wujingz-turn", 0)
end)

return wujingz
