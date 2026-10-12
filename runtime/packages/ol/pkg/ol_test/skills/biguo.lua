local biguo = fk.CreateSkill {
  name = "biguo",
}

Fk:loadTranslationTable{
  ["biguo"] = "愎果",
  [":biguo"] = "摸牌阶段开始时，你可以弃置一张牌，从牌堆中展示并获得每种类别的牌各一张。然后你本回合成为牌的目标后，你可以与一名其他角色拼点，"..
  "没赢的角色本回合不能使用或打出与双方拼点牌类别相同的牌。",

  ["#biguo-invoke"] = "愎果：你可以弃置一张牌，获得每种类别的牌各一张",
  ["#biguo-choose"] = "愎果：你可以与一名角色拼点，没赢的角色本回合不能使用打出与拼点牌类别相同的牌",
  ["@biguo-turn"] = "愎果",

  ["$biguo1"] = "",
  ["$biguo2"] = "",
}

biguo:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biguo.name) and player.phase == Player.Draw and
      not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = biguo.name,
      cancelable = true,
      prompt = "#biguo-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, biguo.name, player, player)
    if player.dead then return end
    local cards = {}
    for _, type in ipairs({ "basic", "trick", "equip" }) do
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..type))
    end
    if #cards > 0 then
      room:showCards(cards)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, biguo.name, nil, true, player)
    end
  end,
})

biguo:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biguo.name) and
      player:usedSkillTimes(biguo.name, Player.HistoryTurn) > 0 and
      table.find(player.room.alive_players, function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#biguo-choose",
      skill_name = biguo.name,
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
    local pindian = player:pindian({ to }, biguo.name)
    local types = {}
    if pindian.fromCard then
      table.insert(types, pindian.fromCard:getTypeString().."_char")
    end
    if pindian.results[to].toCard then
      table.insertIfNeed(types, pindian.results[to].toCard:getTypeString().."_char")
    end
    for _, p in ipairs({ player, to }) do
      if pindian.results[to].winner ~= p and not p.dead then
        local mark = p:getTableMark("@biguo-turn")
        table.insertTableIfNeed(mark, types)
        room:setPlayerMark(p, "@biguo-turn", mark)
      end
    end
  end,
})

biguo:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("@biguo-turn"), card:getTypeString().."_char")
  end,
  prohibit_response = function(self, player, card)
    return card and table.contains(player:getTableMark("@biguo-turn"), card:getTypeString().."_char")
  end,
})

return biguo
