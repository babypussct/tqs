
local jihui = fk.CreateSkill {
  name = "jihui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jihui"] = "济惠",
  [":jihui"] = "锁定技，每回合首次有角色回复体力后，你摸一张牌。你本轮首次失去牌数大于体力值后，你获得一张【桃】。",

  ["$jihui1"] = "",
  ["$jihui2"] = "",
}

jihui:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jihui.name) then
      local recover_events = player.room.logic:getEventsOfScope(GameEvent.Recover, 1, Util.TrueFunc, Player.HistoryTurn)
      return #recover_events == 1 and recover_events[1].data == data
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, jihui.name)
  end,
})

jihui:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jihui.name) and player:usedEffectTimes(self.name, Player.HistoryRound) == 0 then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              n = n + 1
            end
          end
        end
      end
      if n > 0 then
        player.room:addPlayerMark(player, "jihui-round", n)
        if player:getMark("jihui-round") > player.hp then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("peach")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, jihui.name, nil, false, player)
    end
  end,
})

return jihui
