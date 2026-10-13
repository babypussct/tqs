local skill = fk.CreateSkill {
  name = "#dull_blade_skill",
  tags = { Skill.Compulsory },
  attached_equip = "dull_blade",
}

Fk:loadTranslationTable{
  ["#dull_blade_skill"] = "无锋剑",
}

skill:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local cards = {}
    for _, id in ipairs(player:getCardIds("he")) do
      if not player:prohibitDiscard(id) and
        not (table.contains(player:getEquipments(Card.SubtypeWeapon), id) and
        Fk:getCardById(id).name == skill.attached_equip) then
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
