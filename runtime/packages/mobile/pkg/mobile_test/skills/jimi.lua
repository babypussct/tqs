local jimi = fk.CreateSkill {
  name = "jimi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jimi"] = "集蜜",
  [":jimi"] = "锁定技，游戏开始时，所有角色将手牌中不为【桃】或【酒】的牌随机替换为牌堆中的等量张【桃】或【酒】；" ..
  "当有【桃】或【酒】不因使用而进入弃牌堆后，你获得一张牌名字数为X的伤害牌（X为本回合进入过弃牌堆的【桃】和【酒】的张数）。",

  ["$jimi1"] = "归附于朕之人，都有蜜吃！",
  ["$jimi2"] = "上等之蜜当配南北绿豆，岂可草草食之？",
  ["$jimi3"] = "此蜜甚是甘甜，让朕精力无限啊！",
  ["$jimi4"] = "不集天下之蜜，何显朕天子之威！",
}

jimi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jimi.name)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jimi.name
    local room = player.room

    local mark = {}
    table.forEach(room:getAlivePlayers(), function(p)
      if p:isAlive() then
        local toPut = table.filter(p:getCardIds("h"), function(id)
          return not table.contains({ "peach", "analeptic" }, Fk:getCardById(id, true).trueName)
        end)

        if #toPut > 0 then
          local positions = {}
          local y = #room.draw_pile
          for _ = 1, #toPut do
            table.insert(positions, math.random(y + 1))
          end
          table.sort(positions, function (a, b) return a > b end)
          local moveInfos = {}
          for i = 1, #toPut do
            table.insert(moveInfos, {
              ids = { toPut[i] },
              from = p,
              toArea = Card.DrawPile,
              moveReason = fk.ReasonJustMove,
              skillName = skillName,
              drawPilePosition = positions[i],
            })
          end
          room:moveCards(table.unpack(moveInfos))

          if p:isAlive() then
            local toObtain = table.filter(room.draw_pile, function(id)
              return table.contains({ "peach", "analeptic" }, Fk:getCardById(id).trueName)
            end)

            room:obtainCard(p, room:tableRandomPick(toObtain, #moveInfos), false, fk.ReasonPrey, p, skillName)

            mark[tostring(p.id)] = p:getCardIds("h")
          end
        end
      end
    end)

    room:setPlayerMark(player, "jimi_record-noclear", mark)
  end,
})

jimi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return
      player:hasSkill(jimi.name) and
      table.find(
        data,
        function(info)
          return
            (info.moveReason ~= fk.ReasonUse or not player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)) and
            info.toArea == Card.DiscardPile and
            table.find(info.moveInfo, function(moveInfo)
              return table.contains({ "peach", "analeptic" }, Fk:getCardById(moveInfo.cardId).trueName)
            end) ~= nil
        end
      )
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local num = 0
    room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      local moves = e.data
      table.forEach(moves, function(move)
        if move.toArea == Card.DiscardPile then
          num = num + #table.filter(move.moveInfo, function(info)
            return table.contains({ "peach", "analeptic" }, Fk:getCardById(info.cardId).trueName)
          end)
        end
      end)
    end, Player.HistoryTurn)

    local cards = table.filter(room.draw_pile, function(id)
      local card = Fk:getCardById(id)
      return (card.is_damage_card or card.name == "lightning") and Fk:translate(card.trueName, "zh_CN"):len() == num
    end)

    if #cards > 0 then
      room:obtainCard(player, room:tableRandomPick(cards), false, fk.ReasonPrey, player, jimi.name)
    end
  end,
})

return jimi
