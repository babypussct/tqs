local qingli = fk.CreateSkill{
  name = "qingli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingli"] = "清励",
  [":qingli"] = "锁定技，每名角色的回合结束时，你将手牌摸至已损失体力值（至多摸至5张）。",

  ["$qingli1"] = "身在红尘心自远，独揖孤舟钓寒秋。",
  ["$qingli2"] = "吾心向明月，世俗于我，如浮云尔。",
}

qingli:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingli.name) and player:getHandcardNum() < math.min(5, player:getLostHp())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(5, player:getLostHp()) - player:getHandcardNum(), qingli.name)
  end,
})

return qingli