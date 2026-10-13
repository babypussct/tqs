local fengjian = fk.CreateSkill {
  name = "jiange__fengjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__fengjian"] = "封缄",
  [":jiange__fengjian"] = "锁定技，当你对一名角色造成伤害后，其使用牌不能指定你为目标，直到其下回合结束。",

  ["@@jiange__fengjian"] = "封缄",
}

fengjian:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengjian.name) and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(data.to, "@@jiange__fengjian", player.id)
  end,
})

fengjian:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jiange__fengjian", 0)
  end,
})

fengjian:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from and from:getMark("@@jiange__fengjian") ~= 0 and card and
      table.contains(from:getTableMark("@@jiange__fengjian"), to.id)
  end,
})

return fengjian
