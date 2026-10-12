local gouding = fk.CreateSkill {
  name = "peixiu_gouding",
}

Fk:loadTranslationTable {
  ["peixiu_gouding"] = "句町",
  [":peixiu_gouding"] = "你获得此技能后，可以失去1点体力，然后摸三张牌。",

  ["#peixiu_gouding-invoke"] = "句町：是否失去1点体力，然后摸三张牌？",
}

gouding:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(gouding.name) and
      data.skill.name == gouding.name and player.hp > 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = gouding.name,
      prompt = "#peixiu_gouding-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, gouding.name)
    if not player.dead then
      player:drawCards(3, gouding.name)
    end
  end
})

return gouding
