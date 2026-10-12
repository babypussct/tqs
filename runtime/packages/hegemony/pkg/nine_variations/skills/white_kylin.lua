
local skill = fk.CreateSkill{
  name = "#white_kylin_skill",
  attached_equip = "white_kylin",
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    if to:hasSkill(skill.name) then
      return 2
    end
  end,
})

skill:addEffect(fk.CardUsing, {
  global = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and
      data.card.name == skill.attached_equip and
      not player.dead and
      table.find(player.room.alive_players, function (p)
        return p.hp > player.hp
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p.hp > player.hp
    end)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = skill.name,
        }
      end
    end
  end,
})

return skill
