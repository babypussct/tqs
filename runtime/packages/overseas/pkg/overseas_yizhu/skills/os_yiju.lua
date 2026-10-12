local yiju = fk.CreateSkill {
  name = "os__yiju",
}

Fk:loadTranslationTable{
  ["os__yiju"] = "蚁聚",
  [":os__yiju"] = "若你有“示”，你于出牌阶段使用【杀】次数上限和攻击范围均为你的体力值。当你受到伤害时，你将“示”置入弃牌堆，令此伤害+1。",

  ["$os__yiju1"] = "鸱张蚁聚，为从天道！",
  ["$os__yiju2"] = "黄天之道，苍天之示。",
}

yiju:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yiju.name) and #player:getPile("os__revelation") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("os__revelation"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, yiju.name, nil, true, player)
    data:changeDamage(1)
  end,
})

yiju:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    return
      (
        player:hasSkill(yiju.name) and
        #player:getPile("os__revelation") > 0 and
        skill.trueName == "slash_skill" and
        scope == Player.HistoryPhase
      ) and
      player.hp - 1 or 0
  end,
})

yiju:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return (from:hasSkill(yiju.name) and #from:getPile("os__revelation") > 0) and from.hp or 0
  end,
})

return yiju
