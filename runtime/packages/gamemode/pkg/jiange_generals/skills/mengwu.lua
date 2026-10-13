local mengwu = fk.CreateSkill {
  name = "jiange__mengwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__mengwu"] = "猛武",
  [":jiange__mengwu"] = "锁定技，你使用【杀】无距离次数限制，当你使用【杀】被抵消后，你摸两张牌。",
}

mengwu:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mengwu.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, mengwu.name)
  end,
})

mengwu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(mengwu.name) and skill.trueName == "slash_skill"
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(mengwu.name) and skill.trueName == "slash_skill"
  end,
})

return mengwu
