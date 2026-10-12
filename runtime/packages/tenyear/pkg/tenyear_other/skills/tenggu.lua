local tenggu = fk.CreateSkill {
  name = "tenggu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tenggu"] = "藤固",
  [":tenggu"] = "锁定技，游戏开始时，你废除防具栏；你视为装备着【藤甲】；当你不因受到火焰伤害而进入濒死状态时，" ..
  "若你的体力上限大于1，则你减1点体力上限并回复体力至上限。",

  ["$tenggu1"] = "好个无礼蛮将，险些给我藤甲踹开线！",
  ["$tenggu2"] = "我没有肚子，这是胃袋。",
}

tenggu:addEffect(fk.GameStart, {
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tenggu.name) and #player:getAvailableEquipSlots(Card.SubtypeArmor) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:abortPlayerArea(player, player:getAvailableEquipSlots(Card.SubtypeArmor))
  end,
})

tenggu:addEffect(fk.PreCardEffect, {
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return
      data.to == player and
      player:hasSkill(tenggu.name) and
      table.contains({"slash", "savage_assault", "archery_attack"}, data.card.name) and
      Fk.skills["#vine_skill"] ~= nil and
      Fk.skills["#vine_skill"]:isEffectable(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/maneuvering/audio/card/vine")
    room:setEmotion(player, "./packages/maneuvering/image/anim/vine")
    data.nullified = true
  end,
})

tenggu:addEffect(fk.DamageInflicted, {
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(tenggu.name) and
      data.damageType == fk.FireDamage and
      Fk.skills["#vine_skill"] ~= nil and
      Fk.skills["#vine_skill"]:isEffectable(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/maneuvering/audio/card/vineburn")
    room:setEmotion(player, "./packages/maneuvering/image/anim/vineburn")
    data:changeDamage(1)
  end,
})

tenggu:addEffect(fk.EnterDying, {
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      not (data.damage and data.damage.damageType == fk.FireDamage) and
      player:hasSkill(tenggu.name) and
      player.maxHp > 1 and
      player.hp < 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:recover{
      who = player,
      num = player.maxHp - player.hp,
      recoverBy = player,
      skillName = tenggu.name,
    }
  end,
})

return tenggu
