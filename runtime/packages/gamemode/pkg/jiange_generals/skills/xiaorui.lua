local xiaorui = fk.CreateSkill {
  name = "jiange__xiaorui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__xiaorui"] = "骁锐",
  [":jiange__xiaorui"] = "锁定技，当友方角色于其回合内使用【杀】造成伤害后，你令其本回合出牌阶段使用【杀】次数上限+1。",
}

xiaorui:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(xiaorui.name) and
      data.card and data.card.trueName == "slash" and
      target:isFriend(player) and player.room.current == target
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, MarkEnum.SlashResidue.."-turn", 1)
  end,
})

return xiaorui
