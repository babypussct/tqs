
local skill = fk.CreateSkill {
  name = "#blood_blade_skill",
  tags = { Skill.Compulsory },
  attached_equip = "blood_blade",
}

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and
      player:usedSkillTimes(skill.name, Player.HistoryTurn) == 0 and
      player:inMyAttackRange(data.to) and
      not table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p) and player:distanceTo(p) > player:distanceTo(data.to)
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh =function (self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard.name == skill.attached_equip and
            Fk:getCardById(info.cardId, true):getMark("blood_blade") == 0 then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    if #ids > 0 then
      for _, move in ipairs(data) do
        if move.from and move.moveReason == fk.ReasonPutIntoDiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and
              info.beforeCard.sub_type == Card.SubtypeWeapon then
              local s = info.beforeCard.equip_skill
              if s then
                for _, id in ipairs(ids) do
                  player.room:setCardMark(Fk:getCardById(id, true), "blood_blade", s.name)
                end
              end
              return
            end
          end
        end
      end
    end
  end,
})

return skill
