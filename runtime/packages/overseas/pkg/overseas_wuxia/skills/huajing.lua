local huajing = fk.CreateSkill {
  name = "huajing",
}

Fk:loadTranslationTable{
  ["huajing"] = "化境",
  [":huajing"] = "游戏开始时，你获得6枚效果不同的“<a href='#WuMarkDesc'>武</a>”标记，拥有此标记的角色增加其此标记数的攻击范围；" ..
  "出牌阶段限一次，你可以展示至多四张花色各不相同的手牌，然后随机获得等量你拥有的“武”标记的效果直到回合结束。" ..
  "具有“武”标记效果的角色装备区里的武器牌失效。",

  ["#WuMarkDesc"] = "剑：当你使用【杀】指定目标后，你随机弃置其两张手牌；<br />" ..
  "刀：当你使用【杀】对目标角色造成伤害时，若其没有手牌，此伤害+1；<br />" ..
  "斧：当你使用的【杀】被抵消后，你对其造成1点伤害；<br />" ..
  "枪：当你使用黑色【杀】结算结束后，你从牌堆或弃牌堆随机获得一张【闪】；<br />" ..
  "戟：当你使用【杀】造成伤害时，你摸一张牌；<br />" ..
  "弓：当你使用【杀】造成伤害后，你随机弃置其装备区里的一张牌。",

  ["huajing_sword"] = "剑",
  ["huajing_blade"] = "刀",
  ["huajing_axe"] = "斧",
  ["huajing_lance"] = "枪",
  ["huajing_halberd"] = "戟",
  ["huajing_bow"] = "弓",
  [":huajing_sword"] = "当你使用【杀】指定目标后，你随机弃置其两张手牌。",
  [":huajing_blade"] = "当你使用【杀】对目标角色造成伤害时，若其没有手牌，此伤害+1。",
  [":huajing_axe"] = "当你使用的【杀】被抵消后，你对其造成1点伤害。",
  [":huajing_lance"] = "当你使用黑色【杀】结算结束后，你从牌堆或弃牌堆随机获得一张【闪】。",
  [":huajing_halberd"] = "当你使用【杀】造成伤害时，你摸一张牌。",
  [":huajing_bow"] = "当你使用【杀】造成伤害后，你随机弃置其装备区里的一张牌。",
}

huajing:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huajing.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local wuMarks = {
      "huajing_sword",
      "huajing_blade",
      "huajing_axe",
      "huajing_lance",
      "huajing_halberd",
      "huajing_bow",
    }
    player.room:setPlayerMark(player, "@[:]huajing", wuMarks)
  end,
})

huajing:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("@[:]huajing") + from:getMark("@[huajingDesc]huajing_effect")
  end,
})

huajing:addEffect("active", {
  prompt = "#huajing-active",
  max_card_num = 4,
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(huajing.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 3 or Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerHand then
      return false
    end

    local card = Fk:getCardById(to_select)
    return
      card.suit ~= Card.NoSuit and
      not table.find(selected, function(id) return Fk:getCardById(id).suit ~= card.suit end)
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = effect.cards

    player:showCards(cards)
    local wuMarks = player:getTableMark("@[:]huajing")
    if player:isAlive() and #wuMarks > 0 then
      local wuEffects = player:getTableMark("@[huajingDesc]huajing_effect")
      table.insertTableIfNeed(wuEffects, table.random(wuMarks, #cards))
      room:setPlayerMark(player, "@[huajingDesc]huajing_effect", wuEffects)
    end
  end,
})

huajing:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:isAlive() and
      data.card.trueName == "slash" and
      data.to:isAlive() and
      not data.to:isKongcheng() and
      table.contains(player:getTableMark("@[huajingDesc]huajing_effect"), "huajing_sword")
  end,
  on_use = function(self, event, target, player, data)
    local canDiscard = data.to:getCardIds("h")
    if data.to == player then
      canDiscard = table.filter(canDiscard, function(id) return not player:prohibitDiscard(id) end)
    end

    if #canDiscard > 0 then
      player.room:throwCard(table.random(canDiscard, 2), huajing.name, data.to, player)
    end
  end,
})

huajing:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and data.card.trueName == "slash") then
      return false
    end

    local huajingEffects = player:getTableMark("@[huajingDesc]huajing_effect")
    local blade = table.contains(huajingEffects, "huajing_blade") and
      data.by_user and
      data.to:isAlive() and
      data.to:isKongcheng()

    local halberd = table.contains(huajingEffects, "huajing_halberd") and
      player:isAlive()

    if blade or halberd then
      event:setCostData(self, { blade = blade, halberd = halberd })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local costData = event:getCostData(self)
    if costData.blade then
      data:changeDamage(1)
    end

    if costData.halberd then
      player:drawCards(1, huajing.name)
    end
  end,
})

huajing:addEffect(fk.CardEffectCancelledOut, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      player:isAlive() and
      data.to:isAlive() and
      table.contains(player:getTableMark("@[huajingDesc]huajing_effect"), "huajing_axe")
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = data.to,
      damage = 1,
      skillName = huajing.name,
    }
  end,
})

huajing:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      data.card.color == Card.Black and
      player:isAlive() and
      table.contains(player:getTableMark("@[huajingDesc]huajing_effect"), "huajing_lance")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local jink = room:getCardsFromPileByRule("jink")
    if #jink == 0 then
      jink = room:getCardsFromPileByRule("jink", 1, "discardPile")
    end

    if #jink > 0 then
      room:obtainCard(player, jink, true, fk.ReasonPrey, player, huajing.name)
    end
  end,
})

huajing:addEffect(fk.Damaged, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      player:isAlive() and
      data.to:isAlive() and
      #data.to:getCardIds("e") > 0 and
      table.contains(player:getTableMark("@[huajingDesc]huajing_effect"), "huajing_bow")
  end,
  on_use = function(self, event, target, player, data)
    local canDiscard = data.to:getCardIds("e")
    if data.to == player then
      canDiscard = table.filter(canDiscard, function(id) return not player:prohibitDiscard(id) end)
    end

    if #canDiscard > 0 then
      player.room:throwCard(table.random(canDiscard), huajing.name, data.to, player)
    end
  end,
})

Fk:addQmlMark({
  name = "huajingDesc",
  how_to_show = function(name, value, player)
    if type(value) == "table" then
      return table.concat(table.map(value, function(val) return val .. "_short" end), "")
    end

    return " "
  end,
  qml_path = "packages/utility/qml/DetailBox",
})

return huajing
