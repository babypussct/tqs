local juejin = fk.CreateSkill {
  name = "juejin",
  tags = { Skill.Permanent, Skill.Limited },
}

Fk:loadTranslationTable{
  ["juejin"] = "决进",
  [":juejin"] = "持恒技，限定技，出牌阶段，你可以令所有角色将体力调整为1并获得X点护甲（X为其以此法减少的体力值，" ..
  "若该角色为你，则+2），然后将牌堆、弃牌堆和所有角色区域内的【酒】、【桃】、【闪】移出游戏。",

  ["#juejin"] = "决进：令所有角色将体力调整为1并转化为护甲，移除【酒】【桃】【闪】！",

  ["$juejin1"] = "朕宁拼一死，逆贼安敢一战！",
  ["$juejin2"] = "朕安可坐受废辱，今日当与卿自出讨之！",
}

juejin:addEffect("active", {
  prompt = "#juejin",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(juejin.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setBanner("juejin_invoked", true)

    if player.general == "mobile__caomao" then
      player.general = "mobile2__caomao"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "mobile__caomao" then
      player.deputyGeneral = "mobile2__caomao"
      room:broadcastProperty(player, "deputyGeneral")
    end

    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isAlive() then
        local diff = 1 - p.hp
        if diff ~= 0 then
          room:changeHp(p, diff, nil, juejin.name)
        end
        if p == player then
          diff = math.min(diff, 0) - 2
        end

        if diff < 0 then
          room:changeShield(p, -diff)
        end
      end
    end

    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(id, true).name) then
        table.insert(cards, id)
      end
    end
    for _, id in ipairs(room.discard_pile) do
      if table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(id, true).name) then
        table.insert(cards, id)
      end
    end

    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("hej")) do
        if table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(id, true).name) then
          table.insert(cards, id)
        end
      end
    end

    if #cards > 0 then
      room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, juejin.name, nil, true, player)
    end
  end,
})

--- 发动后，闪桃酒进入弃牌堆也会移除。存疑，先这么写
juejin:addEffect(fk.AfterCardsMove, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.seat ~= 1 or not player.room:getBanner("juejin_invoked") then return end
    local ids = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if player.room:getCardArea(info.cardId) == Card.DiscardPile
           and table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(info.cardId, true).name) then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    if #ids > 0 then
      event:setCostData(self, { cards = ids })
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.Void, nil, fk.ReasonJustMove, juejin.name, nil, true)
  end,
})

return juejin
