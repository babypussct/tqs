local skill = fk.CreateSkill {
  name = "brocade_box_skill&",
  attached_equip = "brocade_box",
}

Fk:loadTranslationTable{
  ["brocade_box_skill&"] = "锦盒",
  [":brocade_box_skill&"] = "出牌阶段，若有“礼”，你可以将“礼”置入弃牌堆，弃置所有和“礼”花色相同的手牌和装备区内的【锦盒】。",

  ["#brocade_box_skill-ask"] = "将其中一张牌置为 %dest 锦盒的“礼”",
  ["$brocade_box"] = "礼",
  ["#brocade_box"] = "锦盒：弃置【锦盒】、“礼”和所有“礼”花色的手牌",
}

skill:addEffect("active", {
  prompt = "#brocade_box",
  can_use = function(self, player)
    return #player:getPile("$brocade_box") > 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local suit = Fk:getCardById(player:getPile("$brocade_box")[1]).suit
    room:moveCardTo(player:getPile("$brocade_box"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, nil, true, player)
    if not player.dead then
      local ids = {}
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).suit == suit and not player:prohibitDiscard(id) then
          table.insert(ids, id)
        end
      end
      for _, id in ipairs(player:getCardIds("e")) do
        if Fk:getCardById(id).name == skill.attached_equip then
          table.insert(ids, id)
        end
      end
      if #ids > 0 then
        room:throwCard(ids, skill.name, player, player)
      end
    end
  end,
})

skill:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(skill.name) and data.card.name == skill.attached_equip and
      table.contains(data.tos, player) and not target.dead
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(target, {
      target = target,
      flag = { card_data = {{ "Top", room:getNCards(2) }} },
      skill_name = skill.name,
      prompt = "#brocade_box_skill-ask::"..player.id,
    })
    player:addToPile("$brocade_box", card, false, skill.name, target, { target.id })
  end,
})


skill:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getPile("$brocade_box") == 0 then return false end
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId).name == "brocade_box" then
          --多个木马同时移动的情况取其中之一即可，不再做冗余判断
          if info.fromArea == Card.Processing then
            local room = player.room
            --注意到一次交换事件的过程中的两次移动事件都是在一个parent事件里进行的，因此查询到parent事件为止即可
            local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
            if not move_event then return end
            local parent_event = move_event.parent
            local move_events = room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
              if e.id >= move_event.id or e.parent ~= parent_event then return false end
              for _, last_move in ipairs(e.data) do
                if last_move.moveReason == fk.ReasonExchange and last_move.toArea == Card.Processing then
                  return true
                end
              end
            end, parent_event.id)
            if #move_events > 0 then
              for _, last_move in ipairs(move_events[1].data) do
                if last_move.moveReason == fk.ReasonExchange then
                  for _, last_info in ipairs(last_move.moveInfo) do
                    if Fk:getCardById(last_info.cardId).name == "brocade_box" then
                      if last_move.from == player and last_info.fromArea == Card.PlayerEquip then
                        if move.toArea == Card.PlayerEquip then
                          if move.to ~= player then
                            event:setCostData(self, {to = move.to})
                            return true
                          end
                        else
                          event:setCostData(self, {skill_name = move.skillName, toArea = move.toArea})
                          return true
                        end
                      end
                    end
                  end
                end
              end
            end
          elseif move.moveReason == fk.ReasonExchange then
            if move.from == player and info.fromArea == Card.PlayerEquip and move.toArea ~= Card.Processing then
              --适用于被修改了移动区域的情况，如销毁，虽然说原则上移至处理区是不应销毁的
              event:setCostData(self, nil)
              return true
            end
          elseif move.from == player and info.fromArea == Card.PlayerEquip then
            if move.toArea == Card.PlayerEquip then
              if move.to ~= player then
                event:setCostData(self, {to = move.to})
                return true
              end
            else
              event:setCostData(self, {skill_name = move.skillName, toArea = move.toArea})
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
    local cards = player:getPile("$brocade_box")
    local dat = event:getCostData(self)
    if dat.to then
      dat.to:addToPile("$brocade_box", cards, false, skill.name)
    else
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, nil, true)
      if dat.skill_name ~= skill.name and dat.toArea == Card.DiscardPile and not player:isKongcheng() then
        player:throwAllCards("h", skill.name)
      end
    end
  end
})

return skill
