local skill = fk.CreateSkill {
  name = "#ex_nioh_shield_skill",
  tags = { Skill.Compulsory },
  attached_equip = "ex_nioh_shield",
}

Fk:loadTranslationTable{
  ["#ex_nioh_shield_skill"] = "仁王金刚盾",
}

skill:addEffect(fk.PreCardEffect, {
  can_trigger = function(self, event, target, player, data)
    return data.to == player and player:hasSkill(skill.name) and
    data.card.trueName == "slash" and (data.card.color == Card.Black or data.card.suit == Card.Heart)
  end,
  on_use = function (self, event, target, player, data)
    player.room:setEmotion(player, "./packages/standard_cards/image/anim/nioh_shield")
    data.nullified = true
  end,
})

skill:addTest(function(room, me)
  local nioh_shield = room:printCard("nioh_shield")
  local comp2 = room.players[2]

  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = nioh_shield,
    }
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash", Card.Heart),
    }
    lu.assertEquals(me.hp, 4)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash", Card.Diamond),
    }
    lu.assertEquals(me.hp, 3)
  end)
end)

return skill
