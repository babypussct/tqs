local kuizhen = fk.CreateSkill {
  name = "kuizhen",
}

Fk:loadTranslationTable{
  ["kuizhen"] = "溃阵",
  [":kuizhen"] = "出牌阶段限一次，你可以交给一名其他角色任意张手牌并随机获得其等量的手牌，以此法留在其手中的牌称为“溃阵”牌。"..
  "其他角色每次使用“溃阵”牌时，你摸一张牌。其失去全部“溃阵”牌的回合结束时，失去1点体力。",

  ["#kuizhen"] = "溃阵：交给一名其他角色任意张手牌，随机获得其等量的手牌",
  ["@@kuizhen-inhand"] = "溃阵",

  ["$kuizhen1"] = "今一马当先，效霸王破釜！",
  ["$kuizhen2"] = "自古北马皆傲，视南风为鱼俎。",
}

kuizhen:addEffect("active", {
  anim_type = "offensive",
  prompt = "#kuizhen",
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) < 1
  end,
  min_card_num = 1,
  target_num = 1,
  card_filter = function (self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, kuizhen.name, nil, false, player)
    if player.dead or target:isKongcheng() then return end
    local cards = room:tableRandomPick(target:getCardIds("h"), #effect.cards)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, kuizhen.name, nil, false, player)
    if not player:hasSkill(kuizhen.name, true) then return end
    for _, id in ipairs(effect.cards) do
      if table.contains(target:getCardIds("h"), id) then
        room:setCardMark(Fk:getCardById(id), "@@kuizhen-inhand", 1)
        room:addTableMarkIfNeed(player, kuizhen.name, target)
      end
    end
  end,
})

kuizhen:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(kuizhen.name) and
      table.find(data:getMark("@@kuizhen-inhand"), function (mark)
        return mark > 0
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, kuizhen.name)
  end,
})

kuizhen:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuizhen.name) and
      table.find(player:getTableMark(kuizhen.name), function (p)
        return not table.find(p:getCardIds("h"), function (id)
          return Fk:getCardById(id):getMark("@@kuizhen-inhand") > 0
        end) and not p.dead
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets, mark = {}, {}
    for _, p in ipairs(player:getTableMark(kuizhen.name)) do
      if not table.find(p:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@kuizhen-inhand") > 0
      end) then
        table.insert(targets, p)
      else
        table.insert(mark, p)
      end
    end
    room:setPlayerMark(player, kuizhen.name, mark)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:loseHp(p, 1, kuizhen.name, player)
      end
    end
  end,
})

return kuizhen
