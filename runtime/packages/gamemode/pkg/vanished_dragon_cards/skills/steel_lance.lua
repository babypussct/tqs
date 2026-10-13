local skill = fk.CreateSkill {
  name = "#steel_lance_skill",
  attached_equip = "steel_lance",
}

Fk:loadTranslationTable{
  ["#steel_lance_skill"] = "衠钢槊",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and
      not player:isKongcheng() and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(data.to, {
      target = player,
      flag = "h",
      skill_name = skill.name,
    })
    room:throwCard(card, skill.name, player, data.to)
    if player.dead or data.to:isKongcheng() then return end
    card = room:askToChooseCard(player, {
      target = data.to,
      flag = "h",
      skill_name = skill.name,
    })
    room:throwCard(card, skill.name, data.to, player)
  end,
})

return skill
