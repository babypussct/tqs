local zhijue = fk.CreateSkill {
  name = "zhijuet",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhijuet"] = "制绝",
  [":zhijuet"] = "锁定技，你计算与其他角色的距离-2；当你造成伤害后，若你的手牌数小于体力上限，你将手牌摸至体力上限且此技能失效直到回合结束。",

  ["$zhijuet1"] = "裂土而背德者，定斩不赦。",
  ["$zhijuet2"] = "维军备患，拜受王命，永成南疆！",
}

zhijue:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhijue.name) and
      player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    player.room:invalidateSkill(player, zhijue.name, "-turn")
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), zhijue.name)
    end
  end,
})

zhijue:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(zhijue.name) then
      return -2
    end
  end,
})

return zhijue
