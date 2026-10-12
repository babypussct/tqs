
local qingshou = fk.CreateSkill{
  name = "qingshou",
}

Fk:loadTranslationTable{
  ["qingshou"] = "倾守",
  [":qingshou"] = "每回合限一次，有牌被弃置时，若你手牌中有同名牌，你可以令一名角色摸一张牌，此牌不计入手牌上限。",

  ["#qingshou-choose"] = "倾守：你可以令一名角色摸一张牌",
  ["@@qingshou-inhand"] = "不计上限",

  ["$qingshou1"] = "",
  ["$qingshou2"] = "",
}

qingshou:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qingshou.name) and player:usedSkillTimes(qingshou.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if table.find(player:getCardIds("h"), function (id)
              return info.beforeCard.trueName == Fk:getCardById(id).trueName
            end) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      prompt = "#qingshou-choose",
      skill_name = qingshou.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, qingshou.name, nil, "@@qingshou-inhand")
  end,
})

qingshou:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("@@qingshou-inhand") > 0
  end,
})

return qingshou
