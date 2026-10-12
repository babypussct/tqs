local shejian = fk.CreateSkill {
  name = "mobile__shejian",
}

Fk:loadTranslationTable{
  ["mobile__shejian"] = "舌剑",
  [":mobile__shejian"] = "弃牌阶段结束时，若你本阶段弃置过至少两张牌且花色均不相同，你可以弃置一名其他角色一张牌。",

  ["#mobile__shejian-choose"] = "舌剑：你可以弃置一名其他角色一张牌",

  ["$mobile__shejian1"] = "尔等竖子，不堪为伍！",
  ["$mobile__shejian2"] = "请君洗耳，听我之言。",
}

shejian:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shejian.name) and player.phase == Player.Discard then
      local yes = true
      local suits = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              local suit = Fk:getCardById(info.cardId).suit
              if suit ~= Card.NoSuit then
                if not table.insertIfNeed(suits, suit) then
                  yes = false
                  break
                end
              else
                yes = false
                break
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return yes and #suits > 1 and
        table.find(player.room:getOtherPlayers(player, false), function(p)
          return not p:isNude()
        end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shejian.name,
      prompt = "#mobile__shejian-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = shejian.name,
    })
    room:throwCard(id, shejian.name, to, player)
  end,
})

return shejian
