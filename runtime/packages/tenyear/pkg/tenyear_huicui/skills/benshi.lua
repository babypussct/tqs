local benshi = fk.CreateSkill {
  name = "benshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["benshi"] = "奔矢",
  [":benshi"] = "锁定技，你使用【杀】须指定攻击范围内所有角色为目标。你的攻击范围+1。",

  ["#benshi_slash_skill"] = "奔矢：对攻击范围内所有角色使用【杀】",

  ["$benshi1"] = "今，或为鱼肉，或为刀俎。",
  ["$benshi2"] = "所征徭者必死，可先斩之。",
}

benshi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(benshi.name) and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, benshi.name, "offensive")
    player:broadcastSkillInvoke(benshi.name)
  end,
})

benshi:addEffect("filter", {
  card_skill_filter = function (self, card, player)
    if player:hasSkill(benshi.name) and card.trueName == "slash" then
      return "#benshi__slash_skill"
    end
  end,
})

benshi:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:hasSkill(benshi.name) and 1 or 0
  end,
})

return benshi
