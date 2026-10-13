local lianheng = fk.CreateSkill {
  name = "#kq__lianheng",
}

Fk:loadTranslationTable{
  ["#kq__lianheng"] = "合纵连横",
  [":#kq__lianheng"] = "每个回合开始时，所有角色横置；若场上有张仪，则拥有“横”标记的角色无法对横置状态的角色使用牌。",
}

lianheng:addEffect(fk.TurnStart, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("qin__lianheng")
    player:chat("$qin__lianheng")
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.chained and not p.dead then
        p:setChainState(true)
      end
    end
  end,
})

lianheng:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if from and from:getMark("@@qin__lianheng") > 0 then
      return to.chained
    end
  end,
})

return lianheng
