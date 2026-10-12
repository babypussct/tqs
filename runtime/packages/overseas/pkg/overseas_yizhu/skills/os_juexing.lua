local osJuexing = fk.CreateSkill {
  name = "os__juexing"
}

Fk:loadTranslationTable{
  ["os__juexing"] = "绝行",
  [":os__juexing"] = "出牌阶段限一次，你可视为对一名其他角色使用一张【决斗】，该【决斗】生效时，你与其将所有手牌扣置于各自武将牌上，" ..
  "然后摸等同于当前体力值的牌；该【决斗】结算结束后，你与其弃置以此法摸的牌，然后获得扣置于武将牌上的牌。"..
  "<a href='os__veteran'>历战</a>：你以此法摸牌时，摸牌数+1。",

  ["#os__juexing"] = "绝行：你可视为对一名其他角色使用一张【决斗】",
  ["$os__juexing"] = "绝行",
  ["@os__juexing"] = "绝行 历战",
  ["@@os__juexing-inhand"] = "绝行",

  ["$os__juexing1"] = "阿瞒且寄汝首，待吾一骑取之！",
  ["$os__juexing2"] = "杀！尽歼贼败军之众！",
}

osJuexing:addEffect("viewas", {
  prompt = "#os__juexing",
  pattern = "duel",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("duel")
    c.skillName = osJuexing.name
    return c
  end,
  before_use = function(self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.os__juexingEffect = 1
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(osJuexing.name, Player.HistoryPhase) == 0
  end,
})

osJuexing:addEffect(fk.CardEffecting, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "duel" and (data.extra_data or {}).os__juexingEffect == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osJuexing.name
    local room = player.room
    local targets = table.simpleClone(data.use.tos)
    table.insert(targets, data.from)
    room:sortByAction(targets)

    for _, p in ipairs(targets) do
      if p:isAlive() then
        p:addToPile("$os__juexing", p:getCardIds("h"), false, skillName)
        if p:isAlive() then
          local cards = p:drawCards(p.hp + p:getMark("@os__juexing"), skillName)
          table.forEach(cards, function(id) room:setCardMark(Fk:getCardById(id), "@@os__juexing-inhand", 1) end)
        end
      end
    end
    data.extra_data.os__juexingEffect = data.extra_data.os__juexingEffect + 1
  end,
})

osJuexing:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "duel" and (data.extra_data or {}).os__juexingEffect == 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(data.tos)
    table.insert(targets, data.from)
    room:sortByAction(targets)

    for _, p in ipairs(targets) do
      if p:isAlive() then
        local cards = table.filter(p:getCardIds("h"), function(id) return
          Fk:getCardById(id):getMark("@@os__juexing-inhand") > 0 and not p:prohibitDiscard(Fk:getCardById(id))
        end)
        if #cards > 0 then
          room:throwCard(cards, osJuexing.name, p, p)
        end
        if p:isAlive() then
          room:obtainCard(p, p:getPile("$os__juexing"), false, fk.ReasonJustMove, p)
        end
      end
    end
    data.extra_data.os__juexingEffect = data.extra_data.os__juexingEffect + 1
  end,
})

osJuexing:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:usedSkillTimes(osJuexing.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__juexing")
  end,
})

osJuexing:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@os__juexing", 0)
end)

return osJuexing
