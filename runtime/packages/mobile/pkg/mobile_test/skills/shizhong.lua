local shizhong = fk.CreateSkill {
  name = "shizhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shizhong"] = "势众",
  [":shizhong"] = "锁定技，结束阶段，你摸一张牌并展示所有手牌；准备阶段，你摸X张牌（X为你手牌中剩余上次因“势众”展示的牌），" ..
  "若X与你上次展示的牌数相等，则当你本回合造成伤害时，将伤害值改为十万！",

  ["@@shizhong_record-inhand"] = "势众",
  ["@@shizhong_same-noclear"] = "势众",
  ["@@shizhong_buff-turn"] = "势众 十万伤害",

  ["$shizhong1"] = "孤率大军亲征，今日誓破此城。",
  ["$shizhong2"] = "今以众凌寡，岂有不克之理？",
  ["$shizhong3"] = "而今兵临城下，尔等唯死而已。",
}

shizhong:addEffect(fk.EventPhaseStart, {
  audio_index = { 1, 2 },
  can_trigger = function (self, event, target, player, data)
    if not (target == player and player:hasSkill(shizhong.name)) then
      return false
    end

    return
      player.phase == Player.Finish or
      (
        player.phase == Player.Start and
        table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@shizhong_record-inhand") > 0
        end)
      )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = shizhong.name
    local room = player.room

    if player.phase == Player.Finish then
      player:drawCards(1, skillName)
      if not player:isAlive() then
        return false
      end

      player:showCards(player:getCardIds("h"))
      if not player:isAlive() or player:isKongcheng() then
        return false
      end

      table.forEach(player:getCardIds("h"), function(id)
        room:setCardMark(Fk:getCardById(id), "@@shizhong_record-inhand", 1)
      end)

      room:setPlayerMark(player, "@@shizhong_same-noclear", 1)
    else
      local num = 0
      table.forEach(player:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        if card:getMark("@@shizhong_record-inhand") > 0 then
          room:setCardMark(card, "@@shizhong_record-inhand", 0)
          num = num + 1
        end
      end)

      player:drawCards(num, skillName)
      if not (player:isAlive() and player:getMark("@@shizhong_same-noclear") > 0) then
        return false
      end

      room:setPlayerMark(player, "@@shizhong_buff-turn", 1)
    end
  end,
})

shizhong:addEffect(fk.DetermineDamageCaused, {
  audio_index = 3,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@shizhong_buff-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    if data.damage < 100000 then
      data:changeDamage(100000 - data.damage)
    end
  end,
})

shizhong:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return table.find(data, function(move)
      if move.from == player and not (move.to == player and move.toArea == Card.PlayerHand) then
        return table.find(move.moveInfo, function(info)
          return info.beforeCard:getMark("@@shizhong_record-inhand") > 0
        end) ~= nil
      end
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shizhong_same-noclear", 0)
  end,
})

return shizhong
