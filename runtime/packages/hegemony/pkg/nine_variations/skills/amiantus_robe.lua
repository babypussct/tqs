
local skill = fk.CreateSkill{
  name = "#amiantus_robe_skill",
  attached_equip = "amiantus_robe",
}

skill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType ~= fk.NormalDamage
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

skill:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and not data.from.dead and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill.name,
      cancelable = true,
      prompt = "#amiantus_robe-invoke::" .. data.to.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { tos = { data.to }, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, skill.name, player, player)
    if data.from.dead then return end
    room:damage{
      from = player,
      to = data.from,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = skill.name,
    }
  end,
})

return skill
