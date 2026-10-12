
local shushen = fk.CreateSkill{
  name = "hs__shushen",
}

Fk:loadTranslationTable{
  ["hs__shushen"] = "淑慎",
  [":hs__shushen"] = "每回合各限一次，当你回复体力后，你可以令一名其他角色摸两张牌；"..
  "当你一次获得两张或更多牌时，你可以令一名其他角色回复1点体力。",

  ["#hs__shushen-draw"] = "淑慎：你可以令一名其他角色摸两张牌",
  ["#hs__shushen-recover"] = "淑慎：你可以令一名其他角色回复1点体力",

  ["$hs__shushen1"] = "船到桥头自然直。",
  ["$hs__shushen2"] = "妾身无恙，相公请安心征战。",
}

shushen:addEffect(fk.HpRecover, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shushen.name) and
      #player.room:getOtherPlayers(player, false) > 0 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#hs__shushen-draw",
      skill_name = shushen.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(2, shushen.name)
  end,
})

shushen:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shushen.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local n = 0
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
          if n > 1 then
            break
          end
        end
      end
      if n > 1 then
        return table.find(player.room:getOtherPlayers(player, false), function (p)
          return p:isWounded()
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:isWounded()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#hs__shushen-recover",
      skill_name = shushen.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = event:getCostData(self).tos[1],
      num = 1,
      recoverBy = player,
      skillName = shushen.name,
    }
  end,
})

return shushen
