local futu = fk.CreateSkill {
  name = "futu",
  derived_piles = "futu_ye",
}

Fk:loadTranslationTable{
  ["futu"] = "浮图",
  [":futu"] = "每个回合结束时，若你于此回合内：造成的伤害值最多，你将牌堆顶的首张黑色牌置于你的武将牌上，称为“业”；" ..
  "令角色回复的体力最多，你将牌堆顶的首张红色牌置为“业”。当你受到伤害时，你可以移去一张“业”，防止之。",

  ["futu_ye"] = "业",
  ["#futu-protect"] = "浮图：你可以移去一张“业”，防止此伤害",

  ["$futu1"] = "未度有情令得度，已度之者使成佛。",
  ["$futu2"] = "愿我得佛清净声，法音普及无边界。",
  ["$futu3"] = "慈悲为怀，普度众生。",
  ["$futu4"] = "我不入地狱，谁入地狱？",
  ["$futu5"] = "世有三涂五苦，何不往生极乐。",
  ["$futu6"] = "欲界无边烦恼，西天无挂无碍。",
  ["$futu7"] = "身口意业净，智慧乐多闻。",
  ["$futu8"] = "多欲为苦本，知足即富乐。",
}

futu:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(futu.name) then
      return false
    end

    local damageCount = {}
    local room = player.room
    room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data
      if damage.from and damage.damage > 0 then
        damageCount[damage.from] = (damageCount[damage.from] or 0) + damage.damage
      end

      return false
    end)

    local recoverCount = {}
    room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e)
      local recover = e.data
      if recover.recoverBy and recover.num > 0 then
        recoverCount[recover.recoverBy] = (recoverCount[recover.recoverBy] or 0) + recover.num
      end

      return false
    end, Player.HistoryTurn)

    local evil, kind = damageCount[player], recoverCount[player]
    if damageCount[player] then
      for _, damage in pairs(damageCount) do
        if damage > damageCount[player] then
          evil = false
          break
        end
      end
    end

    if recoverCount[player] then
      for _, num in pairs(recoverCount) do
        if num > recoverCount[player] then
          kind = false
          break
        end
      end
    end

    if evil or kind then
      event:setCostData(self, { evil = evil, kind = kind })
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = futu.name
    local room = player.room
    local costData = event:getCostData(self)
    if costData.evil then
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).color == Card.Black then
          player:addToPile("futu_ye", id, true, skillName, player)
          break
        end
      end
    end

    if costData.kind then
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).color == Card.Red then
          player:addToPile("futu_ye", id, true, skillName, player)
          break
        end
      end
    end
  end,
})

futu:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(futu.name) and
      #player:getPile("futu_ye") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local ids = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|futu_ye",
        skill_name = futu.name,
        expand_pile = "futu_ye",
        prompt = "#futu-protect",
      }
    )

    if #ids > 0 then
      event:setCostData(self, { id = ids[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(
      event:getCostData(self).id,
      Card.DiscardPile,
      nil,
      fk.ReasonPutIntoDiscardPile,
      futu.name,
      nil,
      true,
      player
    )

    data:preventDamage()
  end,
})

return futu
