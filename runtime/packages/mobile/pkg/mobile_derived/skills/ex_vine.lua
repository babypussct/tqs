local skill = fk.CreateSkill {
  name = "#ex_vine_skill",
  tags = { Skill.Compulsory },
  attached_equip = "ex_vine",
}

Fk:loadTranslationTable{
  ["#ex_vine_skill"] = "桐油百韧甲",
}

skill:addEffect(fk.PreCardEffect, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.to == player and player:hasSkill(skill.name) and
      table.contains({"slash", "savage_assault", "archery_attack"}, data.card.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sendLog{
      type = "#InvokeSkill",
      from = player.id,
      arg = skill.name,
    }
    room:broadcastPlaySound("./packages/mobile/audio/card/ex_vine")
    room:setEmotion(player, "./packages/maneuvering/image/anim/vine")
    data.nullified = true
  end,
})
skill:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sendLog{
      type = "#InvokeSkill",
      from = player.id,
      arg = skill.name,
    }
    room:broadcastPlaySound("./packages/mobile/audio/card/ex_vineburn")
    room:setEmotion(player, "./packages/maneuvering/image/anim/vineburn")
    data:changeDamage(1)
  end,
})
skill:addEffect(fk.BeforeChainStateChange, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and not player.chained
  end,
  on_use = function (self, event, target, player, data)
    data.prevented = true
  end,
})

return skill
