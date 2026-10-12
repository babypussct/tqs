local laishou = fk.CreateSkill{
  name = "laishou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["laishou"] = "来寿",
  [":laishou"] = "锁定技，当你受到致命伤害时，若你的体力上限小于9，防止此伤害并增加等量的体力上限。准备阶段，若你的体力上限不小于9，你死亡。",

  ["$laishou1"] = "黄耇鲐背，谓之永年。",
  ["$laishou2"] = "养怡和之福，得乔松之寿。",
  ["$laishou3"] = "福寿将终，竟未得期颐！",
}

laishou:addEffect(fk.DetermineDamageInflicted, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(laishou.name) and
      data.damage >= (player.hp + player.shield) and player.maxHp < 9
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(laishou.name, math.random(1, 2))
    room:notifySkillInvoked(player, laishou.name, "defensive")
    local n = data.damage
    data:preventDamage()
    room:changeMaxHp(player, n)
  end,
})
laishou:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(laishou.name) and player.phase == Player.Start and
      player.maxHp > 8
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(laishou.name, 3)
    room:notifySkillInvoked(player, laishou.name, "negative")
    room:killPlayer({who = player})
  end,
})

return laishou
