local zhangwu = fk.CreateSkill{
  name = "zhangwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhangwu"] = "章武",
  [":zhangwu"] = "锁定技，当【飞龙夺凤】进入弃牌堆或进入其他角色的装备区后，你获得之。" ..
  "当你失去【飞龙夺凤】前，你展示此牌并将之置于牌堆底，然后你摸两张牌。",

  ["$zhangwu1"] = "遁剑归一，有凤来仪。",
  ["$zhangwu2"] = "剑气化龙，听朕雷动！",
}

zhangwu:addEffect(fk.BeforeCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhangwu.name) then
      for _, move in ipairs(data) do
        if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerEquip and move.toArea ~= Card.PlayerHand)) and
          (move.moveReason ~= fk.ReasonUse or
          player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data.card.name ~= "dragon_phoenix") then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and
              Fk:getCardById(info.cardId).name == "dragon_phoenix" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    local mirror_moves = {} ---@type MoveCardsData[]
    for _, move in ipairs(data) do
      if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerEquip and move.toArea ~= Card.PlayerHand)) and
        (move.moveReason ~= fk.ReasonUse or
        player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data.card.name ~= "dragon_phoenix") then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and
            Fk:getCardById(info.cardId).name == "dragon_phoenix" then
            table.insert(ids, id)
            table.insert(mirror_info, info)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = move:copy()
          mirror_move.to = nil
          mirror_move.toArea = Card.DrawPile
          mirror_move.drawPilePosition = -1
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    player:showCards(ids)
    table.insertTable(data, mirror_moves)
    if not player.dead then
      player:drawCards(2, zhangwu.name) -- 大摆特摆
    end
  end,
})

zhangwu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhangwu.name) then
      for _, move in ipairs(data) do
        if move.to ~= player and (move.toArea == Card.PlayerEquip or move.toArea == Card.DiscardPile) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "dragon_phoenix" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to ~= player and (move.toArea == Card.PlayerEquip or move.toArea == Card.DiscardPile) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "dragon_phoenix" then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    player.room:obtainCard(player, ids, true, fk.ReasonPrey, player, zhangwu.name)
  end,
})

return zhangwu
