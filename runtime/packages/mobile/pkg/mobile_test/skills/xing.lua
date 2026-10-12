
local xing = fk.CreateSkill {
  name = "mobile__natu_xing",
}

Fk:loadTranslationTable{
  ["mobile__natu_xing"] = "兴",
  [":mobile__natu_xing"] = "游戏开始时，你获得牌堆中所有能够指定目标的锦囊牌每种牌名各一张，称为“兴”（不可使用或弃置且不计入手牌上限）。"..
  "每回合限X次（X为你本回合使用伤害牌数），你造成伤害后，随机令一张“兴”可使用。"..
  "若你手牌中没有不可使用的“兴”，你使用牌无距离次数限制且不可响应。",

  ["@@mobile__natu_xing-inhand"] = "兴",

  ["$mobile__natu_xing1"] = "每一次谋划，都是为了更好的明天。",
  ["$mobile__natu_xing2"] = "为了汉室兴复，为了天下九州。",
}

xing:addEffect(fk.GameStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xing.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, names = {}, {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeTrick and not card.is_passive and
        table.insertIfNeed(names, Fk:getCardById(id).trueName) then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:setPlayerMark(player, xing.name, cards)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xing.name, nil, false, player, "@@mobile__natu_xing-inhand")
    end
  end,
})

xing:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xing.name) and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mobile__natu_xing-inhand") > 0 and
          table.contains(player:getTableMark(xing.name), id)
      end) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) <
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
        return e.data.from == player and e.data.card.damage_type ~= nil
      end, Player.HistoryTurn)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@mobile__natu_xing-inhand") > 0 and
        table.contains(player:getTableMark(xing.name), id)
    end)
    room:removeTableMark(player, xing.name, room:tableRandomPick(cards))
  end,
})

xing:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return table.find(Card:getIdList(card), function (id)
      return Fk:getCardById(id):getMark("@@mobile__natu_xing-inhand") > 0 and
        table.contains(player:getCardIds("h"), id) and
        table.contains(player:getTableMark(xing.name), id)
    end)
  end,
  prohibit_discard = function (self, player, card)
    return card:getMark("@@mobile__natu_xing-inhand") > 0
  end,
})

xing:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("@@mobile__natu_xing-inhand") > 0
  end,
})

xing:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(xing.name) and card and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mobile__natu_xing-inhand") > 0 and
          table.contains(player:getTableMark(xing.name), id)
      end)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return player:hasSkill(xing.name) and card and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mobile__natu_xing-inhand") > 0 and
          table.contains(player:getTableMark(xing.name), id)
      end)
  end,
})

xing:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(xing.name) and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mobile__natu_xing-inhand") > 0 and
          table.contains(player:getTableMark(xing.name), id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return xing
