local kuanggu = fk.CreateSkill{
  name = "hs__kuanggu",
}

Fk:loadTranslationTable{
  ["hs__kuanggu"] = "狂骨",
  [":hs__kuanggu"] = "当你对距离1以内的角色造成1点伤害后，你可以摸一张牌或回复1点体力。",

  ["$hs__kuanggu1"] = "我会怕你吗！",
  ["$hs__kuanggu2"] = "真是美味啊！",
}

kuanggu:addEffect(fk.Damage, {
  anim_type = "drawcard",
  trigger_times = function (self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuanggu.name) and target == player and (data.extra_data or {}).kuanggucheck
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "draw1" }
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = kuanggu.name,
      cancelable = true,
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

return kuanggu
