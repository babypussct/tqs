local skill = fk.CreateSkill {
  name = "#mukashi_gusoku_skill",
  attached_equip = "mukashi_gusoku",
}

skill:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.damage > 1 or data.damage >= (player.hp + player.shield))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@mukashi_gusoku-turn", 1)
    local cards = table.filter(player:getCardIds("e"), function (id)
      return Fk:getCardById(id).name == skill.attached_equip
    end)
    room:moveCards({
      ids = cards,
      from = player,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = skill.name,
    })
  end,
})

skill:addEffect(fk.DamageInflicted, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@mukashi_gusoku-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

return skill
