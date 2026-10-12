local xialei = fk.CreateSkill {
  name = "xialei",
}

Fk:loadTranslationTable{
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可以观看牌堆顶三张牌，获得其中一张并可以将其余牌置于牌堆底，然后你本回合观看牌数-1。",

  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#xialei-prey"] = "霞泪：获得其中一张牌",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
}

xialei:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xialei.name) and player:getMark("xialei-turn") < 3 then
      local room = player.room
      local toUseOrResponse, toPindian, toConfirm = {}, {}, {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                info.beforeCard.color == Card.Red then
                return true
              end
            end
          else
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.Processing then
                if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse then
                  table.insert(toUseOrResponse, info.cardId)
                elseif move.moveReason == fk.ReasonPindian then
                  table.insert(toPindian, info.cardId)
                else
                  table.insert(toConfirm, info.cardId)
                end
              end
            end
          end
        end
      end
      if #toUseOrResponse > 0 then
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
          local use = parent_event.data ---@type UseCardData|RespondCardData
          if use.from == player and use.subcardsFromInfo then
            for _, info in ipairs(use.subcardsFromInfo) do
              if table.removeOne(toUseOrResponse, info.cardId) and info.from == player and
                --(info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                --使用木马里的牌也能发动，故不判fromArea
                info.beforeCard.color == Card.Red then
                return true
              end
            end
          end
        end
      end
      if #toPindian > 0 then
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        if parent_event.event == GameEvent.Pindian then
          local pindian = parent_event.data ---@type PindianData
          if pindian.from == player and pindian.fromCard.color == Card.Red then
            for _, id in ipairs(room:getSubcardsByRule(pindian.fromCard)) do
              if table.removeOne(toPindian, id) then
                return true
              end
            end
          end
          for to, result in pairs(pindian.results) do
            if to == player and result.toCard.color == Card.Red then
              for _, id in ipairs(room:getSubcardsByRule(result.toCard)) do
                if table.removeOne(toPindian, id) then
                  return true
                end
              end
            end
          end
        end
      end
      if #toConfirm > 0 then
        local can_invoke = false
        local start_id = room.logic:getCurrentEvent().id
        room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
          if e.id < start_id then
            for _, move in ipairs(e.data) do
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(toConfirm, info.cardId) and move.from == player and
                  (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                  info.beforeCard.color == Card.Red then
                  can_invoke = true
                  return true
                end
              end
            end
            return (#toConfirm == 0)
          end
        end, 0)
        return can_invoke
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    room:turnOverCardsFromDrawPile(player, ids, xialei.name, false)
    if #ids == 1 then
      room:obtainCard(player, ids, false, fk.ReasonJustMove, player, xialei.name)
    else
      local card = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ "Top", ids }} },
        skill_name = xialei.name,
        prompt = "#xialei-prey",
      })
      room:obtainCard(player, card, false, fk.ReasonJustMove, player, xialei.name)
      if player.dead then
        room:cleanProcessingArea(ids)
        return
      end
      table.removeOne(ids, card)
      local choice = room:askToChoice(player, {
        choices = { "xialei_top", "xialei_bottom" },
        skill_name = xialei.name,
      })
      room:returnCardsToDrawPile(player, ids, xialei.name, choice == "xialei_top" and "top" or "bottom", false)
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
})

xialei:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "xialei-turn", 0)
end)

local AI = Fk.Ltk.AI
xialei:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return xialei
