local aosi = fk.CreateSkill {
  name = "aosi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["aosi"] = "骜肆",
  [":aosi"] = "锁定技，当你于出牌阶段对一名在你攻击范围内的其他角色造成伤害后，你于此阶段对其使用牌无次数限制。",

  ["@@aosi-phase"] = "骜肆",

  ["$aosi1"] = "凶慢骜肆，天生狂骨！",
  ["$aosi2"] = "暴戾恣睢，傲视诸雄！",
}

aosi:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aosi.name) and player.phase == Player.Play and
      data.to:getMark("@@aosi-phase") == 0 and not data.to.dead and player:inMyAttackRange(data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@@aosi-phase", 1)
    room:addTableMark(player, "aosi-phase", data.to.id)
  end,
})
aosi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("aosi-phase"), to.id)
  end,
})

return aosi
