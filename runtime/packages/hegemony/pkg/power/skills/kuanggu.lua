local kuanggu = fk.CreateSkill{
  name = "xuanhuo__hs__kuanggu",
}
kuanggu:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuanggu.name) and target == player and (data.extra_data or {}).kuanggucheck
  end,
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if player:isWounded() then
      table.insert(choices, 2, "recover")
    end
    local choice = room:askToChoice(player,{
      choices = choices,
      skill_name = kuanggu.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = kuanggu.name
      })
    elseif choice == "draw1" then
      player:drawCards(1, kuanggu.name)
    end
  end,
})
kuanggu:addEffect(fk.BeforeHpChanged, {
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and player == data.damageEvent.from and player:compareDistance(target, 2, "<")
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.kuanggucheck = true
  end,
})

kuanggu:addTest(function (room, me)
  FkTest.setNextReplies(me, {"recover", "draw1", "draw1"})
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, kuanggu.name)
    room:loseHp(me, 3)
    room:damage({ from = me, to = room.players[2], damage = 1})
    room:damage({ from = me, to = room.players[3], damage = 1})
  end)
  lu.assertEquals(me.hp, 2)
  lu.assertEquals(me:getHandcardNum(), 0)
  FkTest.runInRoom(function ()
    room:damage({ from = me, to = room.players[2], damage = 1})
  end)
  lu.assertEquals(me:getHandcardNum(), 1)
end)

Fk:loadTranslationTable{
  ["xuanhuo__hs__kuanggu"] = "狂骨",
  [":xuanhuo__hs__kuanggu"] = "当你对距离1以内的角色造成1点伤害后，你可摸一张牌或回复1点体力。",
}

return kuanggu
