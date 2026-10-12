local ol__liubing = fk.CreateSkill {
  name = "ol__liubing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol__liubing"] = "流兵",
  [":ol__liubing"] = "锁定技，你每回合使用的第一张实体【杀】的花色视为<font color='red'>♦</font>。" ..
      "若其他角色于其出牌阶段内使用的非黑色【杀】未造成伤害，此牌进入弃牌堆后，你获得之。",

  ["$ol__liubing1"] = "尔等流寇，亦可展吾军之勇。",
  ["$ol__liubing2"] = "流寇不堪大用，勤加操练可为精兵。",
}
ol__liubing:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(ol__liubing.name) and target.phase == Player.Play and
        data.card.trueName == "slash" and data.card.color ~= Card.Black and not data.damageDealt
        and player.room:getCardArea(data.card) == Card.Processing and not data.card:isRuleVirtual()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local leftRealCardIds = room:getSubcardsByRule(data.card, { Card.Processing })
    room.logic:getCurrentEvent():addCleaner(function()
      player.room:obtainCard(player, leftRealCardIds, true, fk.ReasonPrey, player, ol__liubing.name)
    end)
  end,
})

ol__liubing:addEffect(fk.AfterCardUseDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(ol__liubing.name) and
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
      card.skillName = ol__liubing.name
      card.suit = Card.Diamond
      card.color = Card.Red
      data.card = card
    end
  end,
})

return ol__liubing
