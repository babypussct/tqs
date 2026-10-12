local mingdian = fk.CreateSkill {
  name = "mingdian",
}

Fk:loadTranslationTable{
  ["mingdian"] = "明典",
  [":mingdian"] = "出牌阶段或当你受到伤害后，你可重铸任意张基本牌（每轮每个牌名限一次）。若你重铸了你本回合使用过的牌名，"..
  "你获得一张手牌中未拥有牌名的基本牌。",

  ["#mingdian"] = "明典：你可以重铸任意张基本牌",

  ["$mingdian1"] = "谄员蔽信，心利锥刀，岂居台府之任！",
  ["$mingdian2"] = "陛列庸夫，智昏麦菽，何当机衡之重？",
}

mingdian:addEffect("active", {
  anim_type = "control",
  prompt = "#mingdian",
  min_card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function (self, player, to_select, selected)
    return Fk:getCardById(to_select).type == Card.TypeBasic and
      not table.contains(player:getTableMark("mingdian-round"), Fk:getCardById(to_select).trueName)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local yes = false
    for _, id in ipairs(effect.cards) do
      room:addTableMark(player, "mingdian-round", Fk:getCardById(id).trueName)
      if not yes and
        #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          return e.data.from == player and Fk:getCardById(id).trueName == e.data.card.trueName
        end, Player.HistoryTurn) > 0 then
        yes = true
      end
    end
    room:recastCard(effect.cards, player, mingdian.name)
    if not player.dead and yes then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).type == Card.TypeBasic and
          not table.find(player:getCardIds("h"), function (id2)
            return Fk:getCardById(id).trueName == Fk:getCardById(id2).trueName
          end) then
          table.insert(cards, id)
        end
      end
      if #cards > 0 then
        room:obtainCard(player, room:tableRandomPick(cards), false, fk.ReasonJustMove, player, mingdian.name)
      end
    end
  end,
})

mingdian:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(mingdian.name) and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = mingdian.name,
      prompt = "#mingdian",
      cancelable = true,
      skip = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local skill = Fk.skills[mingdian.name]
    skill:onUse(player.room, {
      from = player,
      cards = event:getCostData(self).cards,
    })
  end,
})

return mingdian
