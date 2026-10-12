
local binglun = fk.CreateSkill {
  name = "ty__binglun",
}

Fk:loadTranslationTable{
  ["ty__binglun"] = "病论",
  [":ty__binglun"] = "每回合限一次，有角色受到牌造成的伤害时，你可以将此牌置于一名角色的武将牌上，称为“论”。"..
  "有“论”的角色每回合首次使用与“论”花色相同的牌无次数限制。若一名角色拥有相同花色的“论”时，移除其此花色的“论”，其摸两张牌并回复1点体力。",

  ["ty__binglun_pile"] = "论",
  ["#ty__binglun-choose"] = "病论：你可以将%arg置为一名角色的“论”",

  ["$ty__binglun1"] = "",
  ["$ty__binglun2"] = "",
}

binglun:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(binglun.name) and
      data.card and player:usedSkillTimes(binglun.name, Player.HistoryTurn) == 0 and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = binglun.name,
      prompt = "#ty__binglun-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    to:addToPile("ty__binglun_pile", data.card, true, binglun.name, player)
    if #to:getPile("ty__binglun_pile") > 0 then
      local suits = {}
      for _, id in ipairs(to:getPile("ty__binglun_pile")) do
        local suit = Fk:getCardById(id):getSuitString()
        suits[suit] = suits[suit] or {}
        table.insert(suits[suit], id)
      end
      local cards = {}
      for _, ids in pairs(suits) do
        if #ids > 1 then
          table.insertTable(cards, ids)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, binglun.name, nil, true)
        if not to.dead then
          to:drawCards(2, binglun.name)
        end
        if not to.dead then
          room:recover{
            who = to,
            num = 1,
            recoverBy = player,
            skillName = binglun.name,
          }
        end
      end
    end
  end,
})

binglun:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      table.find(player:getPile("ty__binglun_pile"), function (id)
        return Fk:getCardById(id).suit == data.card.suit
      end) and
      player:getMark("ty__binglun-turn") == 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "ty__binglun-turn", 1)
    data.extraUse = true
  end,
})

binglun:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and player:getMark("ty__binglun-turn") == 0 and
      table.find(player:getPile("ty__binglun_pile"), function (id)
        return Fk:getCardById(id).suit == card.suit
      end)
  end,
})

return binglun
