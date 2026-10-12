local skill = fk.CreateSkill {
  name = "#ol__catapult_skill",
  attached_equip = "ol__catapult",
}

Fk:loadTranslationTable{
  ["#ol__catapult_skill"] = "霹雳车",
  ["#ol__catapult-invoke"] = "霹雳车：你可以弃置 %dest 区域内的一张牌",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.to ~= player and not data.to:isAllNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#ol__catapult-invoke::"..data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      skill_name = skill.name,
      target = data.to,
      flag = "hej",
    })
    room:throwCard(card, skill.name, data.to, player)
  end,
})

return skill
