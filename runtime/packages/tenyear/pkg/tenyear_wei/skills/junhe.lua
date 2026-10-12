local junhe = fk.CreateSkill{
  name = "junhe",
}

Fk:loadTranslationTable{
  ["junhe"] = "军合",
  [":junhe"] = "准备阶段，你可以展示任意张颜色或类别相同的牌并获得“军合”效果：你下X次（X为你展示的牌数+1）："..
  "造成伤害时，可弃置一张与所有展示牌颜色或类别均相同的牌，令此伤害+1；受到伤害后，摸两张牌。",

  ["#junhe-invoke"] = "军合：你可展示任意张颜色或类别相同的牌，获得展示牌数+1次“军合”效果",
  ["@junhe"] = "军合",
  ["#junhe-discard"] = "军合：你可弃置一张%arg牌，令此伤害+1",
  ["#junhe-discard_combine"] = "军合：你可弃置一张%arg牌或%arg2，令此伤害+1",

  ["$junhe1"] = "聚兵如铁，方能碎尽敌胆。",
  ["$junhe2"] = "万众一口，可吞千里之国。",
}

junhe:addAuxActiveSkill("junhe_active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    if #selected > 0 then
      local colors, types = {}, {}
      for _, id in ipairs(selected) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
        table.insertIfNeed(types, Fk:getCardById(id).type)
      end
      if #colors > 1 then
        return Fk:getCardById(to_select).type == types[1]
      end
      if #types > 1 then
        return Fk:getCardById(to_select).color == colors[1]
      end
      return table.contains(colors, Fk:getCardById(to_select).color) or
        table.contains(types, Fk:getCardById(to_select).type)
    else
      return Fk:getCardById(to_select).color ~= Card.NoColor
    end
  end,
})

junhe:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(junhe.name) and
      player.phase == Player.Start and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(
      player,
      {
        skill_name = "junhe_active",
        prompt = "#junhe-invoke",
        cancelable = true,
      }
    )
    if success and dat then
      event:setCostData(self, { cards = dat.cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}

    local firstCard = Fk:getCardById(cards[1])
    local color = firstCard:getColorString()
    local cardType = firstCard:getTypeString()
    player:showCards(cards)

    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if card:getColorString() ~= color then
        color = nil
      end

      if card:getTypeString() ~= cardType then
        cardType = nil
      end

      if not (color or cardType) then
        return false
      end
    end
    room:setPlayerMark(player, "@junhe", #cards + 1)
    room:setPlayerMark(player, "junhe_record", { color = color, type = cardType })
  end,
})

local removeJunheMark = function(player)
  local room = player.room
  room:removePlayerMark(player, "@junhe", 1)
  if player:getMark("@junhe") == 0 then
    room:setPlayerMark(player, "junhe_record", 0)
  end
end

junhe:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player:isNude() and player:getMark("@junhe") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local junheRecord = player:getMark("junhe_record")
    local pattern
    local prompt
    if junheRecord.color and junheRecord.type then
      local canDiscard = table.filter(player:getCardIds("he"), function(id)
        local card = Fk:getCardById(id)
        return
          (
            card:getColorString() == junheRecord.color or
            card:getTypeString() == junheRecord.type
          ) and
          not player:prohibitDiscard(card)
      end)

      pattern = tostring(Exppattern{ id = canDiscard })
      prompt = "#junhe-discard_combine:::" .. junheRecord.color .. ":" .. junheRecord.type
    elseif junheRecord.color then
      pattern = ".|.|" .. junheRecord.color
      prompt = "#junhe-discard:::" .. junheRecord.color
    elseif junheRecord.type then
      pattern = ".|.|.|.|.|" .. junheRecord.type
      prompt = "#junhe-discard:::" .. junheRecord.type
    else
      return false
    end

    local ids = player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        pattern = pattern,
        include_equip = true,
        skill_name = junhe.name,
        prompt = prompt,
        skip = true,
      }
    )

    if #ids > 0 then
      removeJunheMark(player)
      event:setCostData(self, { cards = ids })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, junhe.name, player, player)
    data:changeDamage(1)
  end,
})

junhe:addEffect(fk.Damaged, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@junhe") > 0
  end,
  on_use = function (self, event, target, player, data)
    removeJunheMark(player)
    player:drawCards(2, junhe.name)
  end,
})

return junhe
