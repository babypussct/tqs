local yanyu = fk.CreateSkill {
  name = "ol_ex__yanyu",
}

Fk:loadTranslationTable{
  ["ol_ex__yanyu"] = "燕语",
  [":ol_ex__yanyu"] = "出牌阶段，你可以重铸【杀】。出牌阶段结束时，若你本阶段失去过至少两张【杀】，你可以令一名男性角色摸两张牌。",

  ["#ol_ex__yanyu"] = "燕语：你可以重铸【杀】",
  ["#ol_ex__yanyu-draw"] = "燕语：你可以令一名男性角色摸两张牌",

  ["$ol_ex__yanyu1"] = "默听莺儿啼，云林一段松花满。",
  --出自明代吴承恩《蝶恋花・其二》，“云林一段松花满，默听莺啼，巧舌如调管。”
  ["$ol_ex__yanyu2"] = "闲看燕子归，耳畔不闻干戈声。",
}

yanyu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ol_ex__yanyu",
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, effect.from, yanyu.name)
  end,
})

yanyu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == player.Play and player:hasSkill(yanyu.name) and
      table.find(player.room.alive_players, function(p)
        return p:isMale()
      end) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.beforeCard.trueName == "slash" and info.fromArea == Card.PlayerHand then
                n = n + 1
                if n > 1 then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return n > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = yanyu.name,
      targets = table.filter(player.room.alive_players, function(p)
        return p:isMale()
      end),
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__yanyu-draw",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(2, yanyu.name)
  end,
})

return yanyu
