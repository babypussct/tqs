local mobileFozong = fk.CreateSkill {
  name = "mobile__fozong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__fozong"] = "佛宗",
  [":mobile__fozong"] = "锁定技，你与因“净土”获得的牌颜色相同的手牌不计入手牌上限，且造成伤害与回复体力的值均+1。",

  ["$mobile__fozong1"] = "世尊割肉饲鹰，而吾舍身度人。",
  ["$mobile__fozong2"] = "诸恶莫作，众善奉行。",
  ["$mobile__fozong3"] = "善恶报应，祸福相承，素来无谁代者。",
  ["$mobile__fozong4"] = "信我法者，即可见佛。",
  ["$mobile__fozong5"] = "踊跃忏悔，消万千罪业。",
  ["$mobile__fozong6"] = "离欲解脱，是为极乐。",
}

mobileFozong:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(mobileFozong.name)) then
      return false
    end

    local subCards = Card:getIdList(data.card)
    return
      #subCards > 0 and
      table.every(subCards, function(id)
        local room = player.room
        return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.fozongIsHand = player
  end,
})

mobileFozong:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if
      not (
        data.card and
        player:hasSkill(mobileFozong.name) and
        table.contains(player:getTableMark("@jingtu-color"), data.card:getColorString()) and
        room.logic:damageByCardEffect(false)
      )
    then
      return false
    end

    local effect = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    return effect and (effect.data.extra_data or {}).fozongIsHand == player
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

mobileFozong:addEffect(fk.PreHpRecover, {
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if
      not (
        data.card and
        player:hasSkill(mobileFozong.name) and
        table.contains(player:getTableMark("@jingtu-color"), data.card:getColorString())
      )
    then
      return false
    end

    local effect = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    return effect and (effect.data.extra_data or {}).fozongIsHand == player
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

mobileFozong:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(mobileFozong.name) and table.contains(player:getTableMark("@jingtu-color"), card:getColorString())
  end,
})

return mobileFozong
