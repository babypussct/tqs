local jingzhong = fk.CreateSkill {
  name = "jingzhong",
}

Fk:loadTranslationTable{
  ["jingzhong"] = "敬重",
  [":jingzhong"] = "弃牌阶段结束时，若你本阶段弃置过至少两张黑色牌，你可以选择一名其他角色；其下回合出牌阶段限三次，当其使用牌结算后，你获得之。",

  ["#jingzhong-choose"] = "敬重：你可以选择一名角色，获得其下回合出牌阶段使用的前三张牌",
  ["@@jingzhong"] = "敬重",

  ["$jingzhong1"] = "妾所乏为容，试问君有几德？",
  ["$jingzhong2"] = "君好色轻德，何谓百德皆备？",
}

jingzhong:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jingzhong.name) and player.phase == Player.Discard then
      local n = 0
      local logic = player.room.logic
      logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).color == Card.Black then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return n > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = player.room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#jingzhong-choose",
        skill_name = jingzhong.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@jingzhong", player.id)
  end,
})

jingzhong:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if
      target.phase == Player.Play and
      table.find(target:getTableMark("@@jingzhong"), function(id)
        local p = player.room:getPlayerById(id)
        return
          p == player and
          p:isAlive() and
          target:getMark("jingzhong_count" .. p.id .. "-turn") < 3
      end)
    then
      local card = Card:getIdList(data.card)
      return #card > 0 and table.every(card, function(id) return player.room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = target:getTableMark("@@jingzhong")
    mark = table.map(mark, function(id) return room:getPlayerById(id) end)
    room:sortByAction(mark)
    local src = table.find(mark, function(p)
      return p:isAlive() and target:getMark("jingzhong_count" .. p.id .. "-turn") < 3
    end)

    if src then
      room:addPlayerMark(target, "jingzhong_count" .. src.id .. "-turn")
      room:obtainCard(src, data.card, true, fk.ReasonJustMove)
    end
  end,
})

jingzhong:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@jingzhong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jingzhong", 0)
  end,
})

return jingzhong
