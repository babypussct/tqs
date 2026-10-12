local qingleng = fk.CreateSkill {
  name = "ty__qingleng",
}

Fk:loadTranslationTable{
  ["ty__qingleng"] = "清冷",
  [":ty__qingleng"] = "你成为黑色非转化牌的目标后，你可以弃置任意一名角色一张牌。若此弃牌：是装备牌，该黑色牌对你无效；"..
    "不是装备牌，你可将该黑色牌视为列入下次“酖毒”可使用的牌中。",

  ["#ty__qingleng-choose"] = "清冷：你可以弃置一名角色一张牌",
  ["#ty__qingleng-ask"] = "清冷：是否将%arg列入下次“酖毒”可使用的牌中",

  ["$ty__qingleng1"] = "冰心映冷月，独守一江清秋。",
  ["$ty__qingleng2"] = "水之遇寒，故成冰尔。",
}

qingleng:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingleng.name) and
      data.card.color == Card.Black and not data.card:isVirtual() and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      if p == player then
        return table.find(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end) ~= nil
      else
        return not p:isNude()
      end
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = qingleng.name,
      prompt = "#ty__qingleng-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local skillName = qingleng.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card
    if to == player then
      local ids = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        cancelable = false,
        skip = true
      })
      if #ids > 0 then
        card = Fk:getCardById(ids[1])
        room:throwCard(ids, skillName, player, player)
      end
    else
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = skillName,
      })
      card = Fk:getCardById(id)
      room:throwCard(id, skillName, to, player)
    end
    if card then
      if card.type == Card.TypeEquip then
        data.nullified = true
      elseif player:hasSkill("zhendud", true) and room:askToSkillInvoke(player, {
        skill_name = skillName,
        prompt = "#ty__qingleng-ask:::" .. Fk:getCardById(data.card.id):toLogString(),
      }) then
        room:addTableMark(player, "@$zhendud", data.card.id)
      end
    end
  end,
})

return qingleng
