local zhenting = fk.CreateSkill {
  name = "ty__zhenting",
}

Fk:loadTranslationTable{
  ["ty__zhenting"] = "镇庭",
  [":ty__zhenting"] = "一名角色回合结束时，若本回合至少两名角色受到过伤害，你可以选择一项："..
  "1.令一名本回合受到过伤害的角色回复1点体力并摸一张牌；2.令一名本回合造成过伤害的角色获得两张本回合进入弃牌堆的牌。",

  ["#ty__zhenting-invoke"] = "镇庭：令受到过伤害的角色回复体力并摸一张牌，或令造成过伤害的角色获得两张牌",
  ["ty__zhenting_recover"] = "回复体力并摸牌",
  ["ty__zhenting_card"] = "获得弃牌堆两张牌",
  ["#ty__zhenting-prey"] = "镇庭：获得两张本回合进入弃牌堆的牌",

  ["$ty__zhenting1"] = "臣者，国之股肱，君所倚仗也。",
  ["$ty__zhenting2"] = "忠臣事君，当鞠躬尽瘁，死而后已。",
}

zhenting:addAuxActiveSkill("ty__zhenting_active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = { "ty__zhenting_recover", "ty__zhenting_card" } },
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "ty__zhenting_recover" then
        return table.contains(self.tos or {}, to_select.id)
      else
        return table.contains(self.froms or {}, to_select.id)
      end
    end
  end,
})

zhenting:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(zhenting.name) then
      local froms, tos = {}, {}
      player.room.logic:getActualDamageEvents(1, function (e)
        table.insertIfNeed(tos, e.data.to)
        if e.data.from and #froms == 0 and not e.data.from.dead then
          table.insert(froms, e.data.from)
        end
      end, Player.HistoryTurn)
      if #tos > 1 then
        if table.find(tos, function (p)
          return not p.dead
        end) then
          return true
        end
        if #froms > 0 then
          return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.toArea == Card.DiscardPile then
                for _, info in ipairs(move.moveInfo) do
                  if table.contains(player.room.discard_pile, info.cardId) then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryTurn) > 0
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local froms, tos = {}, {}
    room.logic:getActualDamageEvents(1, function (e)
      if not e.data.to.dead then
        table.insertIfNeed(tos, e.data.to)
      end
      if e.data.from and not e.data.from.dead then
        table.insertIfNeed(froms, e.data.from)
      end
    end, Player.HistoryTurn)
    if #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              return true
            end
          end
        end
      end
    end, Player.HistoryTurn) == 0 then
      froms = {}
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty__zhenting_active",
      prompt = "#ty__zhenting-invoke",
      cancelable = true,
      extra_data = {
        froms = table.map(froms, Util.IdMapper),
        tos = table.map(tos, Util.IdMapper),
      }
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "ty__zhenting_recover" then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = zhenting.name,
      }
      if not to.dead then
        to:drawCards(1, zhenting.name)
      end
    else
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryTurn)
      cards = room:askToChooseCards(to, {
        target = to,
        min = 2,
        max = 2,
        flag = { card_data = {{ "pile_discard", cards }} },
        skill_name = zhenting.name,
        prompt = "#ty__zhenting-prey",
      })
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, zhenting.name, nil, true, to)
    end
  end,
})

return zhenting
