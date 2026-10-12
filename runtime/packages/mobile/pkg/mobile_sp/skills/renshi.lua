local renshi = fk.CreateSkill {
  name = "renshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["renshi"] = "仁释",
  [":renshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害，获得此【杀】并减1点体力上限。",

  ["$renshi1"] = "巾帼于乱世，只能飘零如尘。",
  ["$renshi2"] = "还望您可以手下留情！",
}

renshi:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(renshi.name) and
      data.card and
      data.card.trueName == "slash" and
      player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()

    if
      table.every(Card:getIdList(data.card), function(id)
        return room:getCardArea(id) == Card.Processing
      end)
    then
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, renshi.name)
    end

    room:changeMaxHp(player, -1)
  end,
})

return renshi
