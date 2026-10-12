local julu = fk.CreateSkill {
  name = "peixiu_julu",
}

Fk:loadTranslationTable {
  ["peixiu_julu"] = "巨鹿",
  [":peixiu_julu"] = "你失去♠2~9的牌后，你摸一张牌（每回合限一次）。",
}

julu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(julu.name) and player:usedSkillTimes(julu.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if info.beforeCard.suit == Card.Spade and
                info.beforeCard.number >= 2 and info.beforeCard.number <= 9 then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, julu.name)
  end,
})

return julu
