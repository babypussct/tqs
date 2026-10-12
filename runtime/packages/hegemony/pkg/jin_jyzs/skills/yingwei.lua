local yingwei = fk.CreateSkill {
  name = "heg__yingwei",
  tags = { Skill.DeputyPlace },
}

Fk:loadTranslationTable{
  ["heg__yingwei"] = "盈威",
  [":heg__yingwei"] = "副将技，结束阶段，若你本回合造成伤害数等于摸牌数，你可以重铸至多两张牌。",

  ["#heg__yingwei-invoke"] = "盈威：你可以重铸至多两张牌",

  ["$heg__yingwei1"] = "动如霹雳，威震宵小！",
  ["$heg__yingwei2"] = "行略如风，摧枯拉朽！",
}

yingwei:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yingwei.name) and player.phase == Player.Finish then
      local room = player.room
      local n = 0
      room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        if damage.from == player then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      local m = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.moveReason == fk.ReasonDraw then
            m = m + #move.moveInfo
          end
        end
      end, Player.HistoryTurn)
      return n == m
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 2,
      include_equip = true,
      skill_name = yingwei.name,
      prompt = "#heg__yingwei-invoke",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:recastCard(cards, player, yingwei.name)
  end,
})

return yingwei
