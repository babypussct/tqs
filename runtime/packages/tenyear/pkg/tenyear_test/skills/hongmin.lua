
local hongmin = fk.CreateSkill{
  name = "hongmin",
}

Fk:loadTranslationTable{
  ["hongmin"] = "弘敏",
  [":hongmin"] = "每轮开始时，你可以展示一张手牌，若如此做，直至本轮结束，你防止下次受到的伤害，且有角色弃牌阶段弃置与此牌颜色相同的牌时，"..
  "你获得之，并可以将其中至多五张牌分配给一名其他角色或置于牌堆顶。",

  ["#hongmin-invoke"] = "弘敏：展示一张手牌，你获得弃牌阶段弃置的此颜色牌",
  ["@hongmin-round"] = "弘敏",
  ["#hongmin-give"] = "弘敏：选择其中至多五张牌，分配给一名其他角色或置于牌堆顶",
  ["hongmin_put"] = "置于牌堆顶",

  ["$hongmin1"] = "",
  ["$hongmin2"] = "",
}

hongmin:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(hongmin.name) and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = hongmin.name,
      cancelable = true,
      prompt = "#hongmin-invoke",
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = Fk:getCardById(event:getCostData(self).cards[1]):getColorString()
    player:showCards(event:getCostData(self).cards)
    if player.dead then return end
    room:setPlayerMark(player, "hongmin_damage-round", 1)
    room:setPlayerMark(player, "@hongmin-round", color)
  end,
})

hongmin:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hongmin.name) and player:getMark("hongmin_damage-round") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "hongmin_damage-round", 0)
    data:preventDamage()
  end,
})

hongmin:addAuxActiveSkill("#hongmin_active", {
  min_card_num = 1,
  max_card_num = 5,
  min_target_num = 0,
  max_target_num = 1,
  interaction = UI.OptionBox { options = { "hongmin_put", "reason_give" }, direct_send = true },
  card_filter = function (self, player, to_select, selected, selected_targets)
    return #selected < 5 and table.contains(self.cards, to_select)
  end,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if #selected_cards >= 1 and #selected_cards <= 5 then
      if self.interaction.data == "reason_give" then
        return #selected == 1
      else
        return #selected == 0
      end
    end
  end,
})

hongmin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(hongmin.name) and
      player:getMark("@hongmin-round") ~= 0 and player.room.current.phase == Player.Discard then
      for _, move in ipairs(data) do
        if move.from and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard:getColorString() == player:getMark("@hongmin-round") and
              table.contains(player.room.discard_pile, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, move in ipairs(data) do
      if move.from and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard:getColorString() == player:getMark("@hongmin-round") and
            table.contains(room.discard_pile, info.cardId) then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, hongmin.name, nil, true, player)
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#hongmin_active",
      prompt = "#hongmin-give",
      extra_data = {
        cards = cards
      },
    })
    if success and dat then
      if #dat.targets > 0 then
        room:moveCardTo(dat.cards, Card.PlayerHand, dat.targets[1], fk.ReasonGive, hongmin.name, nil, false, player)
      else
        room:moveCards({
          ids = dat.cards,
          from = player,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = hongmin.name,
          drawPilePosition = 1,
          moveVisible = false,
        })
      end
    end
  end,
})

return hongmin
