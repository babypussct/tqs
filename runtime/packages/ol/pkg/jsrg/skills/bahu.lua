local bahu = fk.CreateSkill {
  name = "ol_bahu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_bahu"] = "跋扈",
  [":ol_bahu"] = "锁定技，准备阶段，你摸一张牌；你出牌阶段使用【杀】的次数限制+1。",
}

bahu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bahu.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, bahu.name)
  end,
})

bahu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(bahu.name) and card and card.trueName == "slash" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return bahu