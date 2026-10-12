
local zongpei = fk.CreateSkill {
  name = "ol_heg__zongpei",
}

Fk:loadTranslationTable{
  ["ol_heg__zongpei"] = "纵辔",
  [":ol_heg__zongpei"] = "每回合限一次，当其他角色的牌不因使用而置入弃牌堆后，你可以获得其中的锦囊牌和坐骑牌。",

  ["#ol_heg__zongpei-invoke"] = "纵辔：是否获得其中的锦囊牌和坐骑牌？",
  ["#ol_heg__zongpei-prey"] = "纵辔：选择要获得的牌",

  ["$ol_heg__zongpei1"] = "",
  ["$ol_heg__zongpei2"] = "",
}

zongpei:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zongpei.name) and player:usedSkillTimes(zongpei.name) == 0 then
      local ids = {}
      for _, move in ipairs(data) do
        if move.moveReason ~= fk.ReasonUse and move.toArea == Card.DiscardPile then
          if move.from then
            if move.from ~= player then
              for _, info in ipairs(move.moveInfo) do
                if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                  (info.beforeCard.type == Card.TypeTrick or
                  info.beforeCard.sub_type == Card.SubtypeDefensiveRide or
                  info.beforeCard.sub_type == Card.SubtypeOffensiveRide) then
                  table.insertIfNeed(ids, info.cardId)
                end
              end
            end
          elseif move.moveReason == fk.ReasonResponse then
            local response_event = player.room.logic:getCurrentEvent():findParent(GameEvent.RespondCard)
            if response_event and response_event.data.from ~= player then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.Processing and
                  (Fk:getCardById(info.cardId).type == Card.TypeTrick or
                  Fk:getCardById(info.cardId).sub_type == Card.SubtypeDefensiveRide or
                  Fk:getCardById(info.cardId).sub_type == Card.SubtypeOffensiveRide) then
                  table.insertIfNeed(ids, info.cardId)
                end
              end
            end
          elseif move.moveReason == fk.ReasonPindian then
            local pindian_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian)
            if pindian_event then
              local card_ids = {}
              pindian_event:searchEvents(GameEvent.MoveCards, 1, function(e)
                for _, move2 in ipairs(e.data) do
                  if move2.from ~= player and move2.moveReason == fk.ReasonPindian and move2.toArea == Card.Processing then
                    for _, info in ipairs(move2.moveInfo) do
                      if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                        (Fk:getCardById(info.cardId).type == Card.TypeTrick or
                        Fk:getCardById(info.cardId).sub_type == Card.SubtypeDefensiveRide or
                        Fk:getCardById(info.cardId).sub_type == Card.SubtypeOffensiveRide) then
                        table.insertIfNeed(card_ids, info.cardId)
                      end
                    end
                  end
                end
              end)
              for _, info in ipairs(move.moveInfo) do
                if table.contains(card_ids, info.cardId) then
                  table.insertIfNeed(ids, info.cardId)
                end
              end
            end
          end
        end
      end
      ids = table.filter(ids, function (id)
        return table.contains(player.room.discard_pile, id)
      end)
      ids = player.room.logic:moveCardsHoldingAreaCheck(ids)
      if #ids > 0 then
        event:setCostData(self, { cards = ids })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zongpei.name,
      prompt = "#ol_heg__zongpei-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.simpleClone(event:getCostData(self).cards or {})
    if #ids > 1 then
      local cards, _ = room:askToChooseCardsAndChoice(player, {
        cards = ids,
        min_num = 1,
        max_num = #ids,
        skill_name = zongpei.name,
        prompt = "#ol_heg__zongpei-prey",
        cancel_choices = { "get_all" },
      })
      if #cards > 0 then
        ids = cards
      end
    end
    room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, zongpei.name, nil, true, player)
  end,
})

return zongpei