local zhouxian = fk.CreateSkill {
  name = "zhouxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhouxian"] = "州贤",
  [":zhouxian"] = "锁定技，当你成为其他角色使用伤害牌的目标时，你亮出牌堆顶三张牌，然后其须弃置一张亮出牌中含有的一种类别的牌，否则取消此目标。",

  ["#zhouxian-discard"] = "州贤：请弃置一张亮出牌中含有的一种类别的牌，否则取消 %arg 对 %dest 的目标",

  ["$zhouxian1"] = "今未有苛暴之乱，汝敢言失政之语。",
  ["$zhouxian2"] = "曹将军神武应期，如何以以身试祸。",
}

zhouxian:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhouxian.name) and
      data.from ~= player and data.card.is_damage_card and not data.cancelled
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhouxian.name
    local room = player.room
    local ids = room:getNCards(3)
    room:moveCardTo(ids, Card.Processing, nil, fk.ReasonJustMove, skillName, nil, true, player)
    local types = {}
    for _, id in ipairs(ids) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end

    room:moveCardTo(
      table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end),
      Card.DiscardPile,
      nil,
      fk.ReasonPutIntoDiscardPile,
      skillName,
      nil,
      true,
      player
    )

    local from = data.from
    if from:isAlive() and not from:isNude() then
      local toDiscard = room:askToDiscard(
        from,
        {
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          pattern = ".|.|.|.|.|" .. table.concat(types, ","),
          prompt = "#zhouxian-discard::" .. player.id .. ":" .. data.card:toLogString(),
        }
      )

      if #toDiscard > 0 then
        return false
      end
    end

    data:cancelCurrentTarget()
  end,
})

return zhouxian
