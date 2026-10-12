local fuling = fk.CreateSkill {
  name = "peixiu_fuling",
}

Fk:loadTranslationTable {
  ["peixiu_fuling"] = "涪陵",
  [":peixiu_fuling"] = "你的装备牌不能被其他角色弃置。",
}

fuling:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fuling.name) and #player:getCardIds("e") > 0 then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard and move.proposer ~= player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and move.proposer ~= player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    player.room:cancelMove(data, ids)
  end,
})

return fuling
