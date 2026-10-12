local wangliec = fk.CreateSkill {
  name = "mobile__wangliec",
}

Fk:loadTranslationTable{
  ["mobile__wangliec"] = "往烈",
  [":mobile__wangliec"] = "出牌阶段开始时，你可以选择一张手牌，你此阶段使用此牌无距离限制且不可被响应，且你使用此牌结算结束后，"..
  "你此阶段不能对其他角色使用牌。",

  ["#mobile__wangliec-invoke"] = "往烈：选择一张手牌，此阶段使用此牌无距离限制且不可被响应，结算后不能对其他角色使用牌",
  ["@@mobile__wangliec-phase"] = "往烈",

  ["$mobile__wangliec1"] = "上将者，但建今日之功，不刊往昔之烈。",
  ["$mobile__wangliec2"] = "一人之兵，如震如霆，霆霆冥冥，天下皆惊。",
}

wangliec:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangliec.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = wangliec.name,
      prompt = "#mobile__wangliec-invoke",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    room:setCardMark(Fk:getCardById(id), "@@mobile__wangliec-phase", player.id)
  end,
})

wangliec:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and #Card:getIdList(card) == 1 and
      Fk:getCardById(Card:getIdList(card)[1]):getMark("@@mobile__wangliec-phase") == player.id
  end,
})

wangliec:addEffect(fk.CardUsing, {
  can_refresh = function (self, event, target, player, data)
    return target == player and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1]):getMark("@@mobile__wangliec-phase") == player.id
  end,
  on_refresh = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

wangliec:addEffect(fk.CardUseFinished, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and not player.dead and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1]):getMark("@@mobile__wangliec-phase") == player.id
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "mobile__wangliec-phase", 1)
  end,
})

wangliec:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return card and to and from and from:getMark("mobile__wangliec-phase") > 0 and from ~= to
  end,
})

return wangliec
