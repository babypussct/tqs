local tingji = fk.CreateSkill{
  name = "tingji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tingji"] = "霆击",
  [":tingji"] = "锁定技，你的回合内，未受伤的其他角色视为在你攻击范围内，且不能响应牌。",

  ["$tingji1"] = "翦之恶暴，其怒如动发雷殷，当振大汉天声。",
  ["$tingji2"] = "玄岂以一子之命，而纵国贼！",
}

tingji:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(tingji.name) and player.room.current == player and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isWounded()
      end)
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
      if not p:isWounded() then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

tingji:addEffect("atkrange", {
  within_func = function (self, from, to)
    if from:hasSkill(tingji.name) and Fk:currentRoom().current == from and not to:isWounded() and to ~= from then
      return true
    end
  end,
})

tingji:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return Fk:currentRoom():getCurrent() and Fk:currentRoom():getCurrent():hasSkill(tingji.name) and
      player ~= Fk:currentRoom():getCurrent() and not player:isWounded() and card and card.is_passive
  end,
})

return tingji
