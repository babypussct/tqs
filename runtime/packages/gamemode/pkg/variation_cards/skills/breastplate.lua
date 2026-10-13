local skill = fk.CreateSkill {
  name = "#breastplate_skill",
  attached_equip = "breastplate",
}

Fk:loadTranslationTable{
  ["#breastplate_skill"] = "护心镜",
}

skill:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.damage > 1 or data.damage >= (player.hp + player.shield))
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    local cards = table.filter(player:getCardIds("e"), function (id)
      return Fk:getCardById(id).name == skill.attached_equip
    end)
    player.room:moveCards({
      ids = cards,
      from = player,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = skill.name,
    })
  end,
})

return skill
