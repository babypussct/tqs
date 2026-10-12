local jiandao = fk.CreateSkill {
  name = "jiandao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiandao"] = "剑道",
  [":jiandao"] = "锁定技，你的伤害锦囊牌视为【决斗】，你使用【决斗】或成为伤害牌目标结算后你摸一张伤害牌（不计次数）。"..
    "当你造成【决斗】伤害后，你下次使用【杀】指定目标，其需弃置一张基本牌，否则此【杀】不可响应。"..
    "你每造成两次伤害，本局游戏你的【杀】伤害+1，并可以选择手牌中一张非伤害替换为伤害牌。",

  ["@@jiandao-inhand"] = "剑道",
  ["@jiandao"] = "剑道",
  ["#jiandao-cards"] = "剑道：你可以弃置一张非伤害手牌并获得一张伤害牌",
  ["#jiandao-discard"] = "剑道：你需弃置一张基本牌，否则此【杀】不可响应",

  ["$jiandao1"] = "剑招有尽，剑意无穷。",
  ["$jiandao2"] = "剑之极境，在力、在速、在巧。",
}

jiandao:addEffect("filter", {
  card_filter = function(self, card, player)
    return player:hasSkill(jiandao.name) and card.type == Card.TypeTrick and card.is_damage_card and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("duel", card.suit, card.number)
  end,
})

jiandao:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if ((data.card.trueName == "duel" and data.from == player) or
      (data.card.is_damage_card and table.contains(data.tos, player))) and player:hasSkill(jiandao.name) then
      --不能嵌套发动
      local events = player.room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      for i = #events, 1, -1 do
        local e = events[i]
        local d = e.data
        if ((d.card.trueName == "duel" and d.from == player) or
          (d.card.is_damage_card and table.contains(d.tos, player))) then
          return d == data
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --移动可见、从牌堆底开始检索、不能拿弃牌堆
    local drawPile = room.draw_pile
    local id
    for i = #drawPile, 1, -1 do
      id = drawPile[i]
      if Fk:getCardById(id).is_damage_card then
        room:obtainCard(player, id, true, fk.ReasonJustMove, player, jiandao.name, "@@jiandao-inhand")
        break
      end
    end
  end,
})

jiandao:addEffect(fk.Damage, {
  anim_type = "offensive",
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, jiandao.name)
    if data.card and data.card.trueName == "duel" then
      room:setPlayerMark(player, "jiandao_slash", 1)
    end
    if player:getMark(jiandao.name) % 2 == 1 then return end
    room:addPlayerMark(player, "@jiandao")
    local cards = player:getCardIds("h")
    if #cards == 0 then return end
    cards = table.filter(cards, function(id)
      return not Fk:getCardById(id).is_damage_card
    end)
    --弃置卡牌、移动不可见、从牌堆底开始检索、可拿弃牌堆
    if #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = jiandao.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#jiandao-cards",
    }) > 0 and not player.dead then
      local pile = room.draw_pile
      local id
      for i = #pile, 1, -1 do
        id = pile[i]
        if Fk:getCardById(id).is_damage_card then
          room:obtainCard(player, id, false, fk.ReasonJustMove, player, jiandao.name)
          return
        end
      end
      pile = table.filter(room.discard_pile, function(id)
        return Fk:getCardById(id).is_damage_card
      end)
      if #pile > 0 then
        room:obtainCard(player, room:tableRandomPick(pile), false, fk.ReasonJustMove, player, jiandao.name)
      end
    end
  end,
})

--【杀】造成伤害时，伤害值+X，可加连环伤害
jiandao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and data.card and data.card.trueName == "slash" and
      player:hasSkill(jiandao.name) and player:getMark("@jiandao") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@jiandao"))
  end,
})

--使用牌时发动（和止息自选），会被无效
jiandao:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and data.card.trueName == "slash" and
      player:hasSkill(jiandao.name) and player:getMark("jiandao_slash") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiandao_slash", 0)
    --仅询问第一个目标是否弃牌，若不弃牌则所有目标都不能响应
    if #data.tos > 0 then
      local to = data.tos[1]
      if to.dead or #room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jiandao.name,
        cancelable = true,
        pattern = ".|.|.|.|.|basic",
        prompt = "#jiandao-discard",
      }) == 0 then
        data.disresponsiveList = table.simpleClone(room.players)
      end
    end
  end,
})

jiandao:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return data.from == player and data.card:getMark("@@jiandao-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end
})

jiandao:addEffect("targetmod", {
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and card:getMark("@@jiandao-inhand") > 0
  end,
})

return jiandao
