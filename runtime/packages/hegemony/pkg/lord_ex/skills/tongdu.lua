local tongdu = fk.CreateSkill {
  name = "ld__tongdu",
}

Fk:loadTranslationTable {
  ["ld__tongdu"] = "统度",
  [":ld__tongdu"] = "与你势力相同的角色的结束阶段，其可以摸X张牌（X为其本回合弃牌阶段弃置的牌数且至多为3）。",

  ["#ld__tongdu-ask"] = "统度：你可以发动%src的“统度”，摸%arg张牌",

  ["$ld__tongdu1"] = "统荆益二州诸物之价，以为民生国祚之大计。",
  ["$ld__tongdu2"] = "铸直百之钱，可平物价，定军民之心。",
}

local H = require "packages.hegemony.util"

tongdu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target.phase ~= Player.Finish or not H.compareKingdomWith(player, target) or not player:hasSkill(tongdu.name)
        or (target ~= player and not player:hasShownSkill(tongdu.name)) then
      return false
    end
    local room = player.room
    local discard_ids = {}
    room.logic:getEventsOfScope(GameEvent.Phase, 1, function(e)
      if e.data.phase == Player.Discard then
        table.insert(discard_ids, { e.id, e.end_id })
      end
      return false
    end, Player.HistoryTurn)
    if #discard_ids > 0 then
      local num = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local in_discard = false
        for _, ids in ipairs(discard_ids) do
          if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
            in_discard = true
            break
          end
        end
        if in_discard then
          for _, move in ipairs(e.data) do
            if move.from == target and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  num = num + 1
                end
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      if num > 0 then
        event:setCostData(self, { n = math.min(3, num) })
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return target.room:askToSkillInvoke(target,
      { skill_name = tongdu.name, prompt = "#ld__tongdu-ask:" .. player.id .. "::" .. event:getCostData(self).n })
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(event:getCostData(self).n, tongdu.name)
  end,
})

return tongdu
