local skill = fk.CreateSkill {
  name = "#certamen__women_dress_skill",
  tags = { Skill.Compulsory },
  attached_equip = "certamen__women_dress",
}

Fk:loadTranslationTable{
  ["#certamen__women_dress_skill"] = "女装",
}

skill:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or not player:isMale() then return end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          local card = info.virtualEquip or info.beforeCard
          if card.name == skill.attached_equip then
            return Fk.skills[skill.name]:isEffectable(player)
          end
        end
      end
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and info.beforeCard.name == skill.attached_equip then
            return Fk.skills[skill.name]:isEffectable(player)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = {}
    for _, id in ipairs(player:getCardIds("he")) do
      if not player:prohibitDiscard(id) and
        not (table.contains(player:getEquipments(Card.SubtypeArmor), id) and
        (player:getVirtualEquip(id) or Fk:getCardById(id)).name == skill.attached_equip) then
        table.insert(cards, id)
      end
    end
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skill.name,
      cancelable = false,
      pattern = tostring(Exppattern{ id = cards }),
    })
  end,
})

return skill
