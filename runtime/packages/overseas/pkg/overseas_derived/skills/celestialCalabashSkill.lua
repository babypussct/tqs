local celestialCalabashSkill = fk.CreateSkill {
  name = "#celestial_calabash_skill",
  tags = {Skill.Compulsory},
  attached_equip = "celestial_calabash",
}

Fk:loadTranslationTable{
  ['#celestial_calabash_skill'] = '灵宝仙葫',
  [':#celestial_calabash_skill'] = '锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。',
}

local function ccOnUse(self, event, target, player, data)
  local room = player.room
  --room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
  room:changeMaxHp(player, 1)
  room:recover({ who = player, num = 1, recoverBy = player, skillName = celestialCalabashSkill.name})
end

celestialCalabashSkill:addEffect(fk.DamageCaused, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(celestialCalabashSkill.name) and target == player and data.damage > 1
  end,
  on_use = ccOnUse,
})

celestialCalabashSkill:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(celestialCalabashSkill.name) and target ~= player
  end,
  on_use = ccOnUse,
})

celestialCalabashSkill:addTest(function (room, me)
  local card = room:printCard("celestial_calabash")
  local comp2 = room.players[2]
  FkTest.runInRoom(function ()
    room:useCard{
      from = me, card = card, tos = {me}
    }
    room:useVirtualCard("analeptic", nil, me, me)
    room:useVirtualCard("slash", nil, me, comp2)
  end)
  lu.assertEquals(me.hp, 5)
  lu.assertEquals(me.maxHp, 5)
  FkTest.runInRoom(function ()
    room:killPlayer{
      who = comp2
    }
  end)
  lu.assertEquals(me.hp, 6)
  lu.assertEquals(me.maxHp, 6)
end)


return celestialCalabashSkill
