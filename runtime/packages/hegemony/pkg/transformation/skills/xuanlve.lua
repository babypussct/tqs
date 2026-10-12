local xuanlve = fk.CreateSkill{
  name = "xuanlve",
}

Fk:loadTranslationTable{
  ["xuanlve"] = "旋略",
  [":xuanlve"] = "当你失去装备区的牌后或于弃牌阶段内弃置过至少两张牌后，你可以弃置一名其他角色的一张牌。",
  ["#xuanlve-discard"] = "旋略：你可以弃置一名其他角色的一张牌",

  ["$xuanlve1"] = "舍辎简装，袭掠如风！",
  ["$xuanlve2"] = "卸甲奔袭，摧枯拉朽！",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
    local pid = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xuanlve-discard",
      skill_name = xuanlve.name,
      cancelable = true,
    })
    if #pid > 0 then
      event:setCostData(self, { tos = pid })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = xuanlve.name,
    })
    room:throwCard(id, xuanlve.name, to, player)
  end,
}

xuanlve:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xuanlve.name) then return end
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return table.find(room:getOtherPlayers(player, false), function(p)
              return not p:isNude()
            end) ~= nil
          end
        end
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xuanlve:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xuanlve.name) and player.phase == Player.Discard and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                n = n + 1
                if n > 1 then return true end
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return n > 1
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return xuanlve
