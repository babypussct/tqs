local shushen = fk.CreateSkill{
  name = "mobile__shushen",
}

Fk:loadTranslationTable{
  ["mobile__shushen"] = "淑慎",
  [":mobile__shushen"] = "每回合各限一次，当你回复体力后，你可以令一名其他角色摸两张牌；"..
  "当你得到牌后，若这些牌的数量大于1，你可以令一名其他角色回复1点体力。",

  ["#mobile__shushen-draw"] = "淑慎：你可以令一名其他角色摸两张牌",
  ["#mobile__shushen-recover"] = "淑慎：你可以令一名其他角色回复1点体力",

  ["$mobile__shushen1"] = "此者国亡之象，夫君岂不知乎？",
  ["$mobile__shushen2"] = "为人妻者，当为夫计。",
}

shushen:addEffect(fk.HpRecover, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shushen.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = shushen.name,
      prompt = "#mobile__shushen-draw",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(2, shushen.name)
  end,
})
shushen:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shushen.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local x = 0
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          x = x + #move.moveInfo
          if x > 1 then break end
        end
      end
      return x > 1 and
        table.find(player.room:getOtherPlayers(player, false), function (p)
          return p:isWounded()
        end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:isWounded()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shushen.name,
      prompt = "#mobile__shushen-recover",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:recover{
      who = to,
      num = 1,
      recoverBy = player,
      skillName = shushen.name,
    }
  end,
})

return shushen
