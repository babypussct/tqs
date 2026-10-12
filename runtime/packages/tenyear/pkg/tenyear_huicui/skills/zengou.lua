local zengou = fk.CreateSkill {
  name = "ty__zengou",
}

Fk:loadTranslationTable {
  ["ty__zengou"] = "谮构",
  [":ty__zengou"] = "出牌阶段限一次，你可以交给一名其他角色至多你体力上限张牌并摸等量的牌，若如此做，其下次回复体力或使用牌后展示所有手牌，" ..
      "每有一张“谮构”牌，其失去1点体力。",

  ["#ty__zengou"] = "谮构：交给一名角色至多%arg张牌并摸等量牌，其下次体力增加或使用牌后失去体力",
  ["@@ty__zengou"] = "谮构",
  ["@@ty__zengou-inhand"] = "谮构",

  ["$ty__zengou1"] = "既已同床异梦，休怪妾身无情。",
  ["$ty__zengou2"] = "我所恨者，唯夏侯子林一人耳。",
}

zengou:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    return "#ty__zengou:::" .. player.maxHp
  end,
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zengou.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player.maxHp
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = effect.cards
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, zengou.name, nil, false, player, "@@ty__zengou-inhand")
    room:setPlayerMark(target, "@@ty__zengou", player.id)
    if not player.dead then
      player:drawCards(#cards, zengou.name)
    end
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room --[[@as Room]]
    room:notifySkillInvoked(player, "ty__zengou", "offensive")
    player:broadcastSkillInvoke("ty__zengou")
    room:setPlayerMark(target, "@@ty__zengou", 0)
    if target:isKongcheng() then return end
    local cards = target:getCardIds("h")
    local n = #table.filter(cards, function(id)
      return Fk:getCardById(id):getMark("@@ty__zengou-inhand") > 0
    end)
    target:showCards(cards)
    if target.dead or n == 0 then return end
    room:loseHp(target, n, zengou.name)
    if target:isKongcheng() then return end
    for _, cid in ipairs(target:getCardIds("h")) do
      if Fk:getCardById(cid):getMark("@@ty__zengou-inhand") > 0 then
        room:setCardMark(Fk:getCardById(cid), "@@ty__zengou-inhand", 0)
      end
    end
  end,
}

zengou:addEffect(fk.HpRecover, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@ty__zengou") == player.id and player:hasSkill("ty__zengou")
        and target:getHandcardNum() > 0 and
        not not table.find(target:getCardIds("h"), function(cid, index, array)
          return Fk:getCardById(cid):getMark("@@ty__zengou-inhand") ~= 0
        end)
  end,
  on_use = spec.on_use,
})

zengou:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@ty__zengou") == player.id and player:hasSkill("ty__zengou")
        and target:getHandcardNum() > 0 and
        not not table.find(target:getCardIds("h"), function(cid, index, array)
          return Fk:getCardById(cid):getMark("@@ty__zengou-inhand") ~= 0
        end)
  end,
  on_use = spec.on_use,
})

zengou:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if (move.from and move.from == player) or (move.to and move.to == player) then
        return player:getMark("@@ty__zengou") ~= 0 and ((player:getHandcardNum() > 0 and
          not table.find(player:getCardIds("h"), function(cid, index, array)
            return Fk:getCardById(cid):getMark("@@ty__zengou-inhand") ~= 0
          end)) or player:isKongcheng())
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty__zengou", 0)
  end
})

return zengou
