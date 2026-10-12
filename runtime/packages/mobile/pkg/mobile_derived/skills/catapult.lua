local skill = fk.CreateSkill {
  name = "#mobile__catapult_skill",
  attached_equip = "mobile__catapult",
}

Fk:loadTranslationTable{
  ["#mobile__catapult_skill"] = "霹雳车",
  ["#mobile__catapult-invoke"] = "霹雳车：你可以弃置 %dest 装备区内的所有牌",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.to ~= player and #data.to:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#mobile__catapult-invoke::"..data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(data.to:getCardIds("e"), skill.name, data.to, player)
  end,
})

return skill
