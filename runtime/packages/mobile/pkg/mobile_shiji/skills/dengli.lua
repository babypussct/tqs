local dengli = fk.CreateSkill {
  name = "dengli",
}

Fk:loadTranslationTable{
  ["dengli"] = "等力",
  [":dengli"] = "当你使用【杀】指定其他角色为目标后，或当你成为其他角色使用【杀】的目标后，若你与其体力值相等，你可以摸一张牌。",

  ["$dengli1"] = "纵尔勇冠天下，吾亦不退半分！",
  ["$dengli2"] = "虚名何足夸口，败吾休得再提！",
}

dengli:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dengli.name) and data.card.trueName == "slash" and
      data.to ~= player and player.hp == data.to.hp
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, dengli.name)
  end,
})
dengli:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dengli.name) and data.card.trueName == "slash" and
      data.from ~= player and player.hp == data.from.hp
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, dengli.name)
  end,
})

return dengli
