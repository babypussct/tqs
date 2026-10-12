local moushi = fk.CreateSkill {
  name = "os__moushi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__moushi"] = "谋识",
  [":os__moushi"] = "锁定技，当你受到伤害时，若造成伤害的牌与上次对你造成伤害的牌颜色相同，则你防止此伤害。",

  ["@os__moushi"] = "谋识",

  ["$os__moushi1"] = "潜谋于无形，胜于不争不费。",
  ["$os__moushi2"] = "欲思其成，必虑其败也。",
}

moushi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moushi.name) and data.card and
      data.card:getColorString() == player:getMark("@os__moushi")
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

moushi:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(moushi.name, true) and data.card
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.NoColor then
      room:setPlayerMark(player, "@os__moushi", 0)
    else
      room:setPlayerMark(player, "@os__moushi", data.card:getColorString())
    end
  end,
})

moushi:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.to == player and damage.card then
        if damage.card.color == Card.NoColor then
          room:setPlayerMark(player, "@os__moushi", 0)
        else
          room:setPlayerMark(player, "@os__moushi", damage.card:getColorString())
        end
        return true
      end
    end, nil, 0)
  end
end)

return moushi
