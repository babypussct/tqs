local zhee = fk.CreateSkill {
  name = "zhee",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhee"] = "谪厄",
  [":zhee"] = "锁定技，游戏开始时，你随机将牌堆中一张【闪电】置入你的判定区；每个回合结束时，若弃牌堆中有【闪电】，你随机将其中一张置入你的判定区。",

  ["$zhee1"] = "既行此道，何惧因果轮回。",
  ["$zhee2"] = "金也收，银也收，生也受，死也受！",
}

zhee:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(zhee.name) and
      not (
        table.contains(player.sealedSlots, Player.JudgeSlot) or
        player:hasDelayedTrick("lightning")
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local lightning = room:getCardsFromPileByRule("lightning", 1)
    if
      #lightning > 0 and
      not (
        table.contains(player.sealedSlots, Player.JudgeSlot) or
        player:hasDelayedTrick("lightning")
      )
    then
      room:moveCards{
        to = player,
        toArea = Player.Judge,
        ids = lightning,
        moveReason = fk.ReasonPut,
        skillName = zhee.name,
      }
    end
  end,
})

zhee:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(zhee.name) and
      table.find(player.room.discard_pile, function(id) return Fk:getCardById(id).name == "lightning" end) and
      not (
        table.contains(player.sealedSlots, Player.JudgeSlot) or
        player:hasDelayedTrick("lightning")
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local lightning = room:getCardsFromPileByRule("lightning", 1, "discardPile")
    if
      #lightning > 0 and
      not (
        table.contains(player.sealedSlots, Player.JudgeSlot) or
        player:hasDelayedTrick("lightning")
      )
    then
      room:moveCards{
        to = player,
        toArea = Player.Judge,
        ids = lightning,
        moveReason = fk.ReasonPut,
        skillName = zhee.name,
      }
    end
  end,
})

return zhee
