
local lianzhu = fk.CreateSkill{
  name = "mobile__lianzhu",
}

Fk:loadTranslationTable{
  ["mobile__lianzhu"] = "连诛",
  [":mobile__lianzhu"] = "出牌阶段限一次，你可以展示一张牌并交给一名其他角色。"..
  "你本阶段对有此牌的角色使用牌无距离次数限制，且对其造成伤害后可以获得此牌。<br>"..
  "一名其他角色于本阶段内获得此牌后，其选择一项：1.交给你一张此牌以外的牌，然后将此牌交给其上家；2.令你摸两张牌。",

  ["#mobile__lianzhu"] = "连诛：交给一名角色一张牌，本阶段对有此牌的角色使用牌无距离次数限制",
  ["#mobile__lianzhu-prey"] = "连诛：是否获得 %dest 的“连诛”牌？",
  ["#mobile__lianzhu-give"] = "连诛：交给 %src 另一张牌并将“连诛”牌交给 %dest，否则 %src 摸两张牌",

  ["$mobile__lianzhu1"] = "速速供出同党，尚且罪不至死！",
  ["$mobile__lianzhu2"] = "此贼罪涉谋逆，汝等俱当连坐！",
}

lianzhu:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__lianzhu",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local id = effect.cards[1]
    player:showCards(id)
    if target.dead or not table.contains(player:getCardIds("he"), id) then return end
    room:setPlayerMark(player, "mobile__lianzhu-phase", id)
    room:obtainCard(target, id, true, fk.ReasonGive, player, lianzhu.name)
  end,
})

lianzhu:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and to and table.contains(to:getCardIds("he"), player:getMark("mobile__lianzhu-phase"))
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and to and table.contains(to:getCardIds("he"), player:getMark("mobile__lianzhu-phase"))
  end,
})

lianzhu:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lianzhu.name) and
      table.contains(data.to:getCardIds("he"), player:getMark("mobile__lianzhu-phase"))
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lianzhu.name,
      prompt = "#mobile__lianzhu-prey::"..data.to.id,
    })
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(player:getMark("mobile__lianzhu-phase"), Card.PlayerHand, player, fk.ReasonPrey, lianzhu.name, nil, false, player)
  end,
})

lianzhu:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(lianzhu.name) and player:getMark("mobile__lianzhu-phase") ~= 0 then
      for _, move in ipairs(data) do
        if move.to and move.to ~= player and not move.to.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.cardId == player:getMark("mobile__lianzhu-phase") then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to
    local id = player:getMark("mobile__lianzhu-phase")
    for _, move in ipairs(data) do
      if move.to and move.to ~= player and not move.to.dead then
        for _, info in ipairs(move.moveInfo) do
          if info.cardId == id then
            to = move.to
            break
          end
        end
        if to then
          break
        end
      end
    end
    local cards = to:getCardIds("he")
    table.removeOne(cards, id)
    cards = room:askToCards(to, {
      skill_name = lianzhu.name,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#mobile__lianzhu-give:" .. player.id .. ":" .. to:getLastAlive().id,
      cancelable = true,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, lianzhu.name, nil, false, to)
      if table.contains(to:getCardIds("h"), id) then
        room:moveCardTo(id, Card.PlayerHand, to:getLastAlive(), fk.ReasonGive, lianzhu.name, nil, false, to)
      end
    else
      player:drawCards(2, lianzhu.name)
    end
  end,
})

return lianzhu
