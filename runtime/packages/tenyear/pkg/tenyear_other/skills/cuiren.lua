local cuiren = fk.CreateSkill({
  name = "cuiren",
})

Fk:loadTranslationTable {
  ["cuiren"] = "淬刃",
  [":cuiren"] = "出牌阶段限一次，你可以弃置一张装备牌，并根据弃置牌的类别获得以下效果直到回合结束：<br>" ..
      "武器：你使用牌无距离和次数限制；<br>防具：你使用牌无法被响应；<br>坐骑，你使用牌指定目标时，可以多指定任意个目标。",

  ["#cuiren"] = "淬刃：弃一张装备牌，根据副类别本回合获得效果",
  ["#cuiren-weapon"] = "淬刃：弃一张武器牌，本回合使用牌无距离次数限制",
  ["#cuiren-armor"] = "淬刃：弃一张防具牌，本回合使用牌无法被响应",
  ["#cuiren-horse"] = "淬刃：弃一张坐骑牌，本回合使用牌可以多指定任意个目标",
  ["#cuiren-choose"] = "淬刃：你可以为%arg额外指定任意个目标",

  ["$cuiren1"] = "",
  ["$cuiren2"] = "",
}

cuiren:addEffect("active", {
  anim_type = "offensive",
  prompt = function(self, player, selected_cards, selected_targets)
    if #selected_cards == 0 then
      return "#cuiren"
    else
      if Fk:getCardById(selected_cards[1]).sub_type == Card.SubtypeWeapon then
        return "#cuiren-weapon"
      elseif Fk:getCardById(selected_cards[1]).sub_type == Card.SubtypeArmor then
        return "#cuiren-armor"
      elseif Fk:getCardById(selected_cards[1]).sub_type == Card.SubtypeOffensiveRide or
          Fk:getCardById(selected_cards[1]).sub_type == Card.SubtypeDefensiveRide then
        return "#cuiren-horse"
      end
    end
    return "#cuiren"
  end,
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).type == Card.TypeEquip and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local type = Fk:getCardById(effect.cards[1]).sub_type
    room:throwCard(effect.cards, cuiren.name, player, player)
    if not player.dead then
      room:addTableMarkIfNeed(player, "cuiren-turn", type)
    end
  end,
})

cuiren:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("cuiren-turn"), Card.SubtypeWeapon)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

cuiren:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(player:getTableMark("cuiren-turn"), Card.SubtypeWeapon)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(player:getTableMark("cuiren-turn"), Card.SubtypeWeapon)
  end,
})

cuiren:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("cuiren-turn"), Card.SubtypeArmor)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

cuiren:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and
        (table.contains(player:getTableMark("cuiren-turn"), Card.SubtypeOffensiveRide) or
          table.contains(player:getTableMark("cuiren-turn"), Card.SubtypeDefensiveRide)) and
        #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 20,
      targets = data:getExtraTargets({ bypass_distances = true }),
      skill_name = cuiren.name,
      prompt = "#cuiren-choose:::" .. data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return cuiren
