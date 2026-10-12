local yizhen = fk.CreateSkill {
  name = "yizhen",
}

Fk:loadTranslationTable{
  ["yizhen"] = "疑阵",
  [":yizhen"] = "当你受到伤害后，你可以与伤害来源互相观看对方手牌，然后各弃置其中一张牌，若这两张牌颜色相同，则你获得之。",

  ["#yizhen-invoke"] = "疑阵：你可以与 %dest 观看对方手牌并弃置其中一张牌，若颜色相同则你获得之",
  ["#yizhen-discard"] = "疑阵：请弃置 %dest 一张手牌",

  ["$yizhen1"] = "十面虚网已张，正待魏主入毂！",
  ["$yizhen2"] = "小儿遥望江东雾，错把草庐作坚城！",
}

yizhen:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(yizhen.name) and
      data.from and
      data.from ~= player and
      not (data.from:isKongcheng() or player:isKongcheng())
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = yizhen.name,
      prompt = "#yizhen-invoke::"..data.from.id,
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local req = Request:new({ player, data.from }, "AskForPoxi")
    req.focus_text = yizhen.name
    req.receive_decode = false

    req:setData(player, {
      type = "AskForCardsChosen",
      data = { { data.from.general, data.from:getCardIds("h") } },
      extra_data = {
        to = data.from.id,
        min = 1,
        max = 1,
        skillName = yizhen.name,
        prompt = "#yizhen-discard::"..data.from.id,
        pattern = ".",
      },
      cancelable = false,
    })
    req:setDefaultReply(player, room:tableRandomPick(data.from:getCardIds("h"), 1))

    req:setData(data.from, {
      type = "AskForCardsChosen",
      data = { { player.general, player:getCardIds("h") } },
      extra_data = {
        to = player.id,
        min = 1,
        max = 1,
        skillName = yizhen.name,
        prompt = "#yizhen-discard::"..player.id,
        pattern = ".",
      },
      cancelable = false,
    })
    req:setDefaultReply(data.from, room:tableRandomPick(player:getCardIds("h"), 1))

    req:ask()
    local id1 = req:getResult(player)[1] or room:tableRandomPick(data.from:getCardIds("h"))
    local id2 = req:getResult(data.from)[2] or room:tableRandomPick(player:getCardIds("h"))
    local yes = Fk:getCardById(id1).color == Fk:getCardById(id2).color
    local moves = {}
    table.insert(moves, {
      ids = { id1 },
      from = data.from,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      skillName = yizhen.name,
      proposer = player,
      moveVisible = true,
    })
    table.insert(moves, {
      ids = { id2 },
      from = player,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      skillName = yizhen.name,
      proposer = data.from,
      moveVisible = true,
    })
    room:moveCards(table.unpack(moves))
    if yes and not player.dead then
      local ids = table.filter({ id1, id2 }, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #ids > 0 then
        room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, yizhen.name, nil, true, player)
      end
    end
  end,
})

return yizhen
