local skill = fk.CreateSkill {
  name = "#seven_stars_precious_sword_skill",
  tags = { Skill.Compulsory },
  attached_equip = "seven_stars_precious_sword",
}

Fk:loadTranslationTable{
  ["#seven_stars_precious_sword_skill"] = "七星宝刀",
}

skill:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == skill.attached_equip then
            return Fk.skills[skill.name]:isEffectable(player)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == skill.attached_equip then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    ids = table.filter(player:getCardIds("ej"), function (id)
      return not table.contains(ids, id) and not player:prohibitDiscard(id)
    end)
    if #ids > 0 then
      room:throwCard(ids, skill.name, player, player)
    end
  end,
})

return skill
