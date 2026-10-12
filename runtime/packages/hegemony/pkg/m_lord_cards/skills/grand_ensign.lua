
local skill = fk.CreateSkill{
  name = "#grand_ensign_skill",
  attached_equip = "grand_ensign",
}

skill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      #player:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(player:getCardIds("he")) do
      if not player:prohibitDiscard(id) and
        not (table.contains(player:getEquipments(Card.SubtypeArmor), id)
         and (player:getVirtualEquip(id) or Fk:getCardById(id)).name == skill.attached_equip) then
        table.insert(cards, id)
      end
    end
    cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#grand_ensign-invoke",
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, skill.name, player, player)
    data:preventDamage()
  end,
})

return skill
