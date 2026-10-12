local breastplateSkill = fk.CreateSkill{
  name = "#sa__breastplate_skill",
  attached_equip = "sa__breastplate",
}

breastplateSkill:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damage >= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = self.name, prompt = "#sa__breastplate-ask:::" .. data.damage .. ":" .. Fk:getDamageNatureName(data.damageType)})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:sendLog{
      type = "#BreastplateSkill",
      from = player.id,
      arg = breastplateSkill.attached_equip,
      arg2 = data.damage,
      arg3 = Fk:getDamageNatureName(data.damageType),
    }
    room:moveCardTo(table.filter(player:getEquipments(Card.SubtypeArmor), function(id) return Fk:getCardById(id).name == "sa__breastplate" end),
      Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
  end,
})

breastplateSkill:addTest(function(room, me)
  local card = room:printCard("sa__breastplate")
  local comp2 = room.players[2]
  FkTest.setNextReplies(me, { "__cancel", "1" })
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = card,
    }
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash"),
    }
  end)
  lu.assertEquals(me.hp, 3)
  lu.assertEquals(#me:getEquipments(Card.SubtypeArmor), 1)
  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    room:damage {
      from = comp2,
      to =  me,
      damage = 3,
    }
    lu.assertEquals(me.hp, 3)
    lu.assertEquals(#me:getEquipments(Card.SubtypeArmor), 0)
  end)
end)

Fk:loadTranslationTable{
  ["sa__breastplate"] = "护心镜",
  ["#sa__breastplate_skill"] = "护心镜",
  [":sa__breastplate"] = "装备牌·防具<br/><b>防具技能</b>：当你受到伤害时，若此伤害大于或等于你当前的体力值，你可将装备区里的【护心镜】置入弃牌堆，然后防止此伤害。",
  ["#sa__breastplate-ask"] = "护心镜：你可将装备区里的【护心镜】置入弃牌堆，防止 %arg 点 %arg2 伤害",
  ["#BreastplateSkill"] = "%from 发动了〖%arg〗，防止了 %arg2 点 %arg3 伤害",
}

return breastplateSkill
