local yangji = fk.CreateSkill {
  name = "yangji",
}

Fk:loadTranslationTable {
  ["yangji"] = "佯疾",
  [":yangji"] = "准备阶段，或你体力或体力上限变化过的阶段结束时，你可以使用一张牌。若此牌未造成伤害，你可以将一张♠牌当【乐不思蜀】" ..
      "对当前回合角色使用。",

  ["#yangji-use"] = "佯疾：你可以使用一张牌，若未造成伤害，可以将一张♠牌当【乐不思蜀】对 %dest 使用",
  ["#yangji-indulgence"] = "佯疾：你可以将一张♠牌当【乐不思蜀】对 %dest 使用",

  ["$yangji1"] = "吾女性烈，非力可强，唯情可欺。",
  ["$yangji2"] = "此身病弱，咳咳，难当社稷之重。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToPlayCard(player, {
      skill_name = yangji.name,
      prompt = "#yangji-use::" .. room.current.id,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      use.extraUse = true
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = table.simpleClone(event:getCostData(self).extra_data)
    room:useCard(use)
    if use and not use.damageDealt and not player.dead and not room.current.dead and
        not player:prohibitUse(Fk:cloneCard("indulgence")) and
        not player:isProhibited(room.current, Fk:cloneCard("indulgence", Card.Spade)) then
      local cards = table.filter(table.connect(player:getHandlyIds(), player:getCardIds("e")), function(id)
        if Fk:getCardById(id).suit == Card.Spade then
          local card = Fk:cloneCard("indulgence")
          card:addSubcard(id)
          return not player:isProhibited(room.current, card)
        end
      end)
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = yangji.name,
        pattern = tostring(Exppattern { id = cards }),
        prompt = "#yangji-indulgence::" .. room.current.id,
        cancelable = true,
      })
      if #card > 0 then
        room:useVirtualCard("indulgence", card, player, room.current, yangji.name)
      end
    end
  end,
}

yangji:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangji.name) and player.phase == Player.Start
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,

})

yangji:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    local hp_changed = room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
      return e.data and e.data.who == player and player:hasSkill(yangji.name)
    end, Player.HistoryPhase)
    local maxhp_changed = room.logic:getEventsOfScope(GameEvent.ChangeMaxHp, 1, function(e)
      return e.data and e.data.who == player and player:hasSkill(yangji.name)
    end, Player.HistoryPhase)
    return #hp_changed > 0 or #maxhp_changed > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return yangji
