local yinzhi = fk.CreateSkill{
  name = "yinzhi",
}

Fk:loadTranslationTable{
  ["yinzhi"] = "阴鸷",
  [":yinzhi"] = "出牌阶段限一次，你可以选择一名其他角色并摸X张牌，该角色直至其回合开始：所有非锁定技失效，"..
  "其每次使用或打出手牌后你摸X张牌（X为本局游戏你对其发动〖阴鸷〗的次数且至多为3）。"..
  "然后其于其回合内不能使用或打出非本回合内获得的牌，若其对你造成伤害，则此效果消失。",

  ["#yinzhi"] = "阴鸷：选择一名角色，摸牌并令其非锁定技失效，直至其回合开始",
  ["@@yinzhi"] = "阴鸷",

  ["$yinzhi1"] = "大袖蔽天穹，日月一息起，逆我者，永堕无明。",
  ["$yinzhi2"] = "枯骨九重阶，血墨万卷诏，孤不怿以天为父！",
}

yinzhi:addEffect("active", {
  anim_type = "control",
  prompt = "#yinzhi",
  card_num = 0,
  target_num = 1,
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if selectable then
      local n = (player:getTableMark(yinzhi.name)[to_select] or 0) + 1
      return "draw" .. math.min(3, n)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local mark = player:getTableMark(yinzhi.name)
    local n = mark[target] or 0
    if n < 3 then
      n = n + 1
    end
    mark[target] = n
    room:setPlayerMark(player, yinzhi.name, mark)
    room:addTableMarkIfNeed(target, "@@yinzhi", player)
    player:drawCards(n, yinzhi.name)
  end,
})

local spec = {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinzhi.name) and
      table.contains(target:getTableMark("@@yinzhi"), player) and
      (player:getTableMark(yinzhi.name)[target] or 0) > 0 and
      data:isUsingHandcard(target)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getTableMark(yinzhi.name)[target], yinzhi.name)
  end,
}
yinzhi:addEffect(fk.CardUseFinished, spec)
yinzhi:addEffect(fk.CardRespondFinished, spec)

yinzhi:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      (table.contains(player:getTableMark("yinzhi_prohibit"), data.to))
  end,
  on_use = function(self, event, target, player, data)
    player.room:removeTableMark(player, "yinzhi_prohibit", data.to)
  end,
})

yinzhi:addEffect(fk.BeforeTurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@@yinzhi") ~= 0 or player:getMark("yinzhi_prohibit") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@@yinzhi")
    if type(mark) == "table" then
      local mark2 = player:getTableMark("yinzhi_prohibit")
      for _, value in ipairs(mark) do
        table.insertIfNeed(mark2, value)
      end
      room:setPlayerMark(player, "@@yinzhi", 0)
      room:setPlayerMark(player, "yinzhi_prohibit", mark2)
    end
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id, true), "yinzhi-turn-inhand", 1)
    end
  end,
})

yinzhi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("yinzhi_prohibit") ~= 0 then
      local handCards = player:getCardIds("h")
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("yinzhi-turn-inhand") ~= 0 and table.contains(handCards, id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("yinzhi_prohibit") ~= 0 then
      local handCards = player:getCardIds("h")
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("yinzhi-turn-inhand") ~= 0 and table.contains(handCards, id)
      end)
    end
  end,
})

yinzhi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@yinzhi") ~= 0 and
      not skill:hasTag(Skill.Compulsory) and skill:isPlayerSkill(from)
  end,
})

return yinzhi
