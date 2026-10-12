local juejue = fk.CreateSkill {
  name = "ld__juejue",
}

Fk:loadTranslationTable {
  ["ld__juejue"] = "决绝",
  [":ld__juejue"] = "你杀死与你势力相同的角色不执行奖惩。<br>"..
  "弃牌阶段开始时，你可以失去1点体力，若如此做，此阶段结束时，若你于此阶段内弃置过手牌，你令所有其他角色依次选择一项："..
  "1.将X张手牌置入弃牌堆；2.受到你造成的1点伤害（X为你于此阶段内弃置的牌数）。",

  ["#ld__juejue-invoke"] = "决绝：你可以失去1点体力，根据弃牌数令所有其他角色执行效果",
  ["#ld__juejue-ask"] = "决绝：将%arg张手牌置入弃牌堆，否则 %src 对你造成1点伤害",
}

local H = require "packages.hegemony.util"

juejue:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juejue.name) and player.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = juejue.name,
      prompt = "#ld__juejue-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, juejue.name)
  end,
})

juejue:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Discard and player:isAlive() and
      player:usedSkillTimes(juejue.name, Player.HistoryPhase) > 0 then
      local n = 0
      local logic = player.room.logic
      logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                n = n + 1
                if n > 1 then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryTurn)
      event:setCostData(self, { num = n })
      return n > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).num
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        local cards = room:askToCards(p, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = juejue.name,
          pattern = ".|.|.|hand",
          prompt = "#ld__juejue-ask:"..player.id.."::"..n,
          cancelable = true,
        })
        if #cards == n then
          room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, juejue.name)
        else
          room:damage {
            from = player,
            to = p,
            damage = 1,
            skillName = juejue.name,
          }
        end
      end
    end
  end,
})

juejue:addEffect(fk.BuryVictim, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(juejue.name) and data.killer == player and H.compareKingdomWith(player, target)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local deathEvent = room.logic:getCurrentEvent():findParent(GameEvent.Death, true).data
    deathEvent.extra_data = deathEvent.extra_data or {}
    deathEvent.extra_data.ignorePunishment = true
  end,
})

return juejue
