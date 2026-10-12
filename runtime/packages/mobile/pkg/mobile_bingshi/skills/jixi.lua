local jixi = fk.CreateSkill {
  name = "m_shi__jixi",
}

Fk:loadTranslationTable{
  ["m_shi__jixi"] = "急袭",
  [":m_shi__jixi"] = "一名角色的回合结束时，若存在本回合成为过你使用牌的目标的其他角色，你可以弃置当前回合角色一张牌，" ..
  "视为使用一张指定其中任意名角色为目标的无视距离的【顺手牵羊】。",

  ["#m_shi__jixi-invoke_you"] = "急袭：你可以弃置自己1张牌并执行后续效果",
  ["#m_shi__jixi-invoke_other"] = "急袭：你可以弃置 %dest 1张牌并执行后续效果",
  ["#m_shi__jixi-use"] = "急袭：请选择任意名本回合成为过你使用牌目标的角色，视为对其使用顺手牵羊",

  ["$m_shi__jixi1"] = "今掩其空虚，破之必矣。",
  ["$m_shi__jixi2"] = "存亡之分，在此一举。",
}

jixi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return
      target:isAlive() and
      player:hasSkill(jixi.name) and
      not target:isNude() and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return
          use.from == player and
          table.find(use.tos or {}, function(p) return p ~= player end) ~= nil
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = jixi.name
    local room = player.room
    local ids = {}
    if target == player then
      ids = room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          prompt = "#m_shi__jixi-invoke_you",
          skip = true,
        }
      )
    else
      ids = room:askToChooseCards(
        player,
        {
          min = 1,
          max = 1,
          flag = "he",
          target = target,
          skill_name = skillName,
          prompt = "#m_shi__jixi-invoke_other::" .. target.id,
          cancelable = true,
        }
      )
    end

    if #ids > 0 then
      event:setCostData(self, { tos = { target }, cards = ids })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = jixi.name
    local room = player.room
    room:throwCard(event:getCostData(self).cards, skillName, target, player)

    if not player:isAlive() then
      return false
    end

    local targets = {}
    player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player then
        table.forEach(use.tos or {}, function(p)
          if p ~= player and p:isAlive() then
            table.insertIfNeed(targets, p)
          end
        end)
      end
    end, Player.HistoryTurn)

    local snatch = Fk:cloneCard("snatch")
    snatch.skillName = skillName
    targets = table.filter(targets, function(p)
      return player:canUseTo(snatch, p, { bypass_distances = true })
    end)

    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = #targets,
        targets = targets,
        skill_name = skillName,
        prompt = "#m_shi__jixi-use",
      }
    )

    if #tos > 0 then
      room:useCard{
        from = player,
        tos = tos,
        card = snatch,
      }
    end
  end,
})

return jixi
