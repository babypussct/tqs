local juece = fk.CreateSkill {
  name = "m_ex__juece",
}

Fk:loadTranslationTable{
  ["m_ex__juece"] = "绝策",
  [":m_ex__juece"] = "结束阶段，你可以对本回合失去过牌的一名其他角色造成1点伤害。",

  ["#m_ex__juece-choose"] = "绝策：选择一名本回合失去过牌的其他角色，对其造成1点伤害",

  ["$m_ex__juece1"] = "束手就擒吧！",
  ["$m_ex__juece2"] = "斩草除根，以绝后患！",
}

juece:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juece.name) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from and move.from ~= player and not move.from.dead then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from and move.from ~= player and not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insertIfNeed(targets, move.from)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_ex__juece-choose",
      skill_name = juece.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = juece.name,
    }
  end,
})

local AI = Fk.Ltk.AI
juece:addAI(AI.reuse("juece", AI.InvokeStrategy))

return juece
