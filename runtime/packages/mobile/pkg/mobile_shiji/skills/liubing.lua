local liubing = fk.CreateSkill {
  name = "liubing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["liubing"] = "流兵",
  [":liubing"] = "锁定技，你每回合使用的第一张非虚拟的【杀】的花色视为<font color='red'>♦</font>。"..
  "其他角色于其出牌阶段内使用的非转化黑色【杀】结算后，若未造成过伤害，你获得之。",

  ["$liubing1"] = "尔等流寇，亦可展吾军之勇。",
  ["$liubing2"] = "流寇不堪大用，勤加操练可为精兵。",
}

liubing:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(liubing.name) and target.phase == Player.Play and
      data.card.trueName == "slash" and data.card.color == Card.Black and not data.damageDealt and
        not data.card:isConverted() and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, liubing.name)
  end,
})
liubing:addEffect(fk.AfterCardUseDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(liubing.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      data.card.trueName == "slash" and not data.card:isRuleVirtual()
  end,
  on_use = function(self, event, target, player, data)
    if data.card.suit ~= Card.Diamond then
      local card = Fk:cloneCard(data.card.name, data.card.suit, data.card.number)
      for k, v in pairs(data.card) do
        if card[k] == nil then
          card[k] = v
        end
      end
      if data.card:isVirtual() then
        card.subcards = data.card.subcards
      else
        card.id = data.card.id
      end
      card.skillNames = data.card.skillNames
      card.skillName = liubing.name
      card.suit = Card.Diamond
      card.color = Card.Red
      data.card = card
    end
  end,
})

return liubing
