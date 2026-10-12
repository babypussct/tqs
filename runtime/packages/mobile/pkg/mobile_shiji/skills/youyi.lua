local youyi = fk.CreateSkill {
  name = "youyi",
}

Fk:loadTranslationTable{
  ["youyi"] = "游医",
  [":youyi"] = "弃牌阶段结束时，你可以将此阶段弃置的牌置入<a href='RenPile_href'>“仁”区</a>。出牌阶段限一次，你可以弃置所有“仁”区的牌，"..
  "令所有角色回复1点体力。",

  ["#youyi"] = "游医：你可以移去所有“仁”区牌，令所有角色回复1点体力",
  ["#youyi-invoke"] = "游医：是否将本阶段弃置的牌置入“仁”区？",

  ["$youyi1"] = "此身行医，志济万千百姓。",
  ["$youyi2"] = "普济众生，永免疾患之苦。",
}

local U = require "packages.utility.utility"

youyi:addEffect("active", {
  anim_type = "support",
  prompt = "#youyi",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedEffectTimes(youyi.name, Player.HistoryPhase) == 0 and #U.GetRenPile(Fk:currentRoom()) > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:doIndicate(player, room.alive_players)
    room:moveCardTo(U.GetRenPile(room), Card.DiscardPile, nil, fk.ReasonJustMove, youyi.name, nil, true, player)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isWounded() and not p.dead then
        room:recover{
          who = p,
          num = 1,
          recoverBy = player,
          skillName = youyi.name,
        }
      end
    end
  end,
})
youyi:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(youyi.name) and player.phase == Player.Discard then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = youyi.name,
      prompt = "#youyi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryPhase)
    room:shuffleTable(ids)
    U.AddToRenPile(player, ids, youyi.name)
  end,
})

return youyi
