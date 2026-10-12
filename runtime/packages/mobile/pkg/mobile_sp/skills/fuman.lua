local fuman = fk.CreateSkill{
  name = "fuman",
}

Fk:loadTranslationTable{
  ["fuman"] = "抚蛮",
  [":fuman"] = "出牌阶段每名角色限一次，你可以将一张【杀】交给一名其他角色，然后其于下个回合结束之前使用“抚蛮”牌时，你摸一张牌。",

  ["#fuman"] = "抚蛮：将一张【杀】交给一名角色，其使用此【杀】时你摸一张牌",
  ["@@fuman-inhand"] = "抚蛮",

  ["$fuman1"] = "恩威并施，蛮夷可为我所用！",
  ["$fuman2"] = "发兵器啦！",
}

fuman:addEffect("active", {
  anim_type = "support",
  prompt = "#fuman",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("fuman-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "fuman-turn", target.id)
    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, fuman.name, {"@@fuman-inhand", player.id})
  end,
})
fuman:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.extra_data and data.extra_data.fuman == player.id and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, fuman.name)
  end,
})
fuman:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1]):getMark("@@fuman-inhand") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.fuman = Fk:getCardById(Card:getIdList(data.card)[1]):getMark("@@fuman-inhand")
  end,
})
fuman:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@fuman-inhand", 0)
    end
  end,
})

return fuman
