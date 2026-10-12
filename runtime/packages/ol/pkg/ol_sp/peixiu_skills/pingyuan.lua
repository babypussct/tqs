local pingyuan = fk.CreateSkill {
  name = "peixiu_pingyuan",
}

Fk:loadTranslationTable {
  ["peixiu_pingyuan"] = "平原",
  [":peixiu_pingyuan"] = "你失去最后的手牌后，你摸一张牌（每回合限一次）。",
}

pingyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(pingyuan.name) and player:isKongcheng() and
      player:usedSkillTimes(pingyuan.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, pingyuan.name)
  end,
})

return pingyuan
