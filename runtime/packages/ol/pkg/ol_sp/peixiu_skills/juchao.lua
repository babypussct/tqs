local juchao = fk.CreateSkill {
  name = "peixiu_juchao",
}

Fk:loadTranslationTable {
  ["peixiu_juchao"] = "居巢",
  [":peixiu_juchao"] = "你获得此技能后，你可以弃置你与一名角色各一张牌。",

  ["#peixiu_juchao-choose"] = "居巢：选择一名角色，弃置你和其各一张牌",
  ["#peixiu_juchao-discard"] = "居巢：弃置你和其各一张牌",
}

Fk:addPoxiMethod{
  name = juchao.name,
  prompt = "#peixiu_juchao-discard",
  card_filter = function(to_select, selected, data)
    if #selected < 2 and not Self:prohibitDiscard(to_select) then
      if #selected == 0 then
        return true
      else
        if table.contains(data[1][2], to_select) then
          return not table.contains(data[1][2], selected[1])
        else
          return not table.contains(data[2][2], selected[1])
        end
      end
    end
  end,
  feasible = function(selected)
    return #selected == 2
  end,
}

juchao:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juchao.name) and data.skill.name == juchao.name and
      table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = juchao.name,
      prompt = "#peixiu_juchao-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card_data, extra_data, visible_data = {}, {}, {}
    if not to:isKongcheng() then
      table.insert(card_data, { to.general, to:getCardIds("h") })
      for _, id in ipairs(to:getCardIds("h")) do
        if not player:cardVisible(id) then
          visible_data[tostring(id)] = false
        end
      end
      if next(visible_data) == nil then visible_data = nil end
      extra_data.visible_data = visible_data
    end
    if #to:getCardIds("e") > 0 then
      table.insert(card_data, { Fk:translate(to.general).." ", to:getCardIds("e") })
    end
    if not player:isKongcheng() then
      table.insert(card_data, { player.general, player:getCardIds("h") })
    end
    if #player:getCardIds("e") > 0 then
      table.insert(card_data, { Fk:translate(player.general).." ", player:getCardIds("e") })
    end
    local result = room:askToPoxi(player, {
      poxi_type = juchao.name,
      data = card_data,
      cancelable = false,
      extra_data = extra_data,
    })
    local cards1 = table.filter(result, function(id)
      return table.contains(player:getCardIds("he"), id)
    end)
    local cards2 = table.filter(result, function(id)
      return table.contains(to:getCardIds("he"), id)
    end)
    local moves = {}
    if #cards1 > 0 then
      table.insert(moves, {
        from = player,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player,
        skillName = juchao.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moves, {
        from = to,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player,
        skillName = juchao.name,
      })
    end
    room:moveCards(table.unpack(moves))
  end
})

return juchao
