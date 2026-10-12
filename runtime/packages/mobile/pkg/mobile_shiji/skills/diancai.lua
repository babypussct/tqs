local diancai = fk.CreateSkill {
  name = "mobile__diancai",
}

Fk:loadTranslationTable{
  ["mobile__diancai"] = "典财",
  [":mobile__diancai"] = "其他角色的出牌阶段结束时，若你于此阶段失去了至少X张牌（X为你的体力值），则你可以将手牌摸至体力上限。",

  ["$mobile__diancai1"] = "资财当为公，不可为私也！",
  ["$mobile__diancai2"] = "财用于公则政明，而后民附也！",
}

diancai:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(diancai.name) and target.phase == Player.Play and player:getHandcardNum() < player.maxHp then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return n >= player.hp
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), diancai.name)
  end,
})

return diancai
