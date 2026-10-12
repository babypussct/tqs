
local shenduanl = fk.CreateSkill {
  name = "shenduanl",
}

Fk:loadTranslationTable{
  ["shenduanl"] = "审断",
  [":shenduanl"] = "当你拼点时，你可以弃置一张牌，改为用牌堆中点数最大的一张牌拼点。"..
  "当一次拼点结算后，赢的角色的拼点牌置于牌堆底，然后本次用K拼点的角色各摸一张牌堆中点数最小的牌。",

  ["#shenduanl-invoke"] = "审断：你可以弃置一张牌，改为用牌堆中点数最大的一张牌拼点",

  ["$shenduanl1"] = "",
  ["$shenduanl2"] = "",
}

shenduanl:addEffect(fk.StartPindian, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shenduanl.name) and not player:isNude() then
      if player == data.from then
        return not data.fromCard
      else
        return table.contains(data.tos, player) and not (data.results[player] and data.results[player].toCard)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shenduanl.name,
      prompt = "#shenduanl-invoke",
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, shenduanl.name, player, player)
    if #room.draw_pile > 0 then
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        n = math.max(n, Fk:getCardById(id).number)
      end
      local id
      for i = #room.draw_pile, 1, -1 do
        if Fk:getCardById(room.draw_pile[i]).number == n then
          id = room.draw_pile[i]
          break
        end
      end
      if player == data.from then
        data.fromCard = Fk:getCardById(id)
      else
        data.results[player] = data.results[player] or {}
        data.results[player].toCard = Fk:getCardById(id)
      end
    end
  end,
})

shenduanl:addEffect(fk.PindianFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenduanl.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(data.tos) do
      if data.results[p].winner then
        local id
        if data.results[p].winner == data.from then
          id = data.fromCard:getEffectiveId()
        else
          id = data.results[p].toCard:getEffectiveId()
        end
        if id and room:getCardArea(id) == Card.Processing then
          room:moveCards({
            ids = { id },
            toArea = Card.DrawPile,
            moveReason = fk.ReasonJustMove,
            skillName = shenduanl.name,
            drawPilePosition = -1,
            moveVisible = true,
          })
        end
      end
    end
    if data.fromCard and data.fromCard.number == 13 and not data.from.dead and #room.draw_pile > 0 then
      local n = 100
      for _, id in ipairs(room.draw_pile) do
        n = math.min(n, Fk:getCardById(id).number)
      end
      local id
      for i = #room.draw_pile, 1, -1 do
        if Fk:getCardById(room.draw_pile[i]).number == n then
          id = room.draw_pile[i]
          break
        end
      end
      room:moveCardTo(id, Card.PlayerHand, data.from, Card.PlayerHand, shenduanl.name)
    end
    for _, p in ipairs(data.tos) do
      if data.results[p].toCard and data.results[p].toCard.number == 13 and not p.dead and #room.draw_pile > 0 then
        local n = 100
        for _, id in ipairs(room.draw_pile) do
          n = math.min(n, Fk:getCardById(id).number)
        end
        local id
        for i = #room.draw_pile, 1, -1 do
          if Fk:getCardById(room.draw_pile[i]).number == n then
            id = room.draw_pile[i]
            break
          end
        end
        room:moveCardTo(id, Card.PlayerHand, p, Card.PlayerHand, shenduanl.name)
      end
    end
  end,
})

return shenduanl
