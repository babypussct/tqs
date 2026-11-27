
local tongling = fk.CreateSkill {
  name = "ld__tongling",
}

Fk:loadTranslationTable {
  ["ld__tongling"] = "通令",
  [":ld__tongling"] = "每回合限一次，当你造成伤害后，你可以视为使用一张【以逸待劳】，然后你可以对该受到伤害的角色使用其他角色因此弃置的【杀】。",

  ["#ld__tongling-invoke"] = "通令：你可以视为使用【以逸待劳】，结算后可以对 %dest 使用因此弃置的【杀】",
  ["#ld__tongling-slash"] = "通令：你可以对 %dest 使用这些【杀】",

  ["$ld__tongling1"] = "孝直溢美之言，特以此小利报之，还望笑纳。",
  ["$ld__tongling2"] = "孟起，莫非甘心为他人座下之客。",
}

local H = require "packages.hegemony.util"

tongling:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongling.name) and
      player:usedSkillTimes(tongling.name, Player.HistoryTurn) == 0 and
      player:canUse(Fk:cloneCard("await_exhausted", nil, nil, tongling.name))
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tongling.name,
      prompt = "#ld__tongling-invoke::"..data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return H.compareKingdomWith(p, player)
    end)
    local use = room:useVirtualCard("await_exhausted", nil, player, targets, tongling.name)
    if player.dead or data.to.dead then return end
    if use and use.extra_data and use.extra_data.ld__tongling_cards then
      local cards = table.filter(use.extra_data.ld__tongling_cards, function (id)
        return table.contains(room.discard_pile, id) and Fk:getCardById(id).trueName == "slash"
      end)
      while #cards > 0 and not player.dead and not data.to.dead do
        use = room:askToUseRealCard(player, {
          pattern = cards,
          skill_name = tongling.name,
          prompt = "#ld__tongling-slash::"..data.to.id,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            extraUse = true,
            exclusive_targets = { data.to.id },
          },
          expand_pile = cards,
        })
        if use then
          table.removeOne(cards, use.card.id)
          cards = table.filter(cards, function (id)
            return table.contains(room.discard_pile, id) and Fk:getCardById(id).trueName == "slash"
          end)
        else
          return
        end
      end
    end
  end,
})

tongling:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card.name == "await_exhausted" and
      table.contains(data.card.skillNames, tongling.name)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getCurrentEvent():searchEvents(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from and move.from ~= player and move.moveReason == fk.ReasonDiscard and
          move.skillName == "await_exhausted_skill" then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end)
    if #cards > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.ld__tongling_cards = cards
    end
  end,
})

return tongling
