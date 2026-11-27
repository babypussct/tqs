
local juejue = fk.CreateSkill {
  name = "ld__juejue",
}

Fk:loadTranslationTable {
  ["ld__juejue"] = "决绝",
  [":ld__juejue"] = "你杀死势力与你相同的角色不执行奖惩。<br>"..
  "弃牌阶段开始时，你可以失去1点体力，令你此阶段结束时，可以对所有体力值小于你此阶段弃牌数的其他角色各造成1点伤害。",

  ["#ld__juejue-invoke"] = "决绝：你可以失去1点体力，此阶段结束时可以对体力值小于弃牌数的其他角色造成伤害",
  ["#ld__juejue-damage"] = "决绝：是否对体力值小于%arg的其他角色各造成1点伤害？",
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
  anim_type = "offensive",
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
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if table.find(player.room:getOtherPlayers(player, false), function (p)
        return p.hp < n
      end) then
        event:setCostData(self, { num = n })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).num
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return p.hp < n
    end)
    if room:askToSkillInvoke(player, {
      skill_name = juejue.name,
      prompt = "#ld__juejue-damage:::"..n,
    }) then
      event:setCostData(self, { tos = targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos or {}
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage {
          from = player,
          to = p,
          damage = 1,
          skillName = juejue.name,
        }
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
