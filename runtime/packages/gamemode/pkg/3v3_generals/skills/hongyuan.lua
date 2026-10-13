local hongyuan = fk.CreateSkill {
  name = "v33__hongyuan",
}

Fk:loadTranslationTable{
  ["v33__hongyuan"] = "弘援",
  [":v33__hongyuan"] = "摸牌阶段，你可以少摸一张牌，若如此做，其他己方角色各摸一张牌。",
}

hongyuan:addEffect(fk.DrawNCards, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hongyuan.name) and data.n > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n - 1
  end,
})

hongyuan:addEffect(fk.AfterDrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(hongyuan.name, Player.HistoryPhase) > 0 and
      #player:getFriends(false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = player:getFriends(false)})
    return true
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(player:getFriends(false)) do
      if not p.dead then
        p:drawCards(1, hongyuan.name)
      end
    end
  end,
})

return hongyuan
