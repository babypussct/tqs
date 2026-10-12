local jiaojin = fk.CreateSkill{
  name = "ol_ex__jiaojin",
}

Fk:loadTranslationTable{
  ["ol_ex__jiaojin"] = "骄矜",
  [":ol_ex__jiaojin"] = "当你受到伤害时，你可以弃置一张非伤害锦囊牌或装备牌，防止此伤害，并获得造成伤害的牌。",

  ["#ol_ex__jiaojin-discard"] = "骄矜：你可以弃置一张牌，防止受到的伤害，获得造成伤害的牌",

  ["$ol_ex__jiaojin1"] = "天家贵胄，岂是汝诏可收？",
  ["$ol_ex__jiaojin2"] = "同泽无怨，哼，惟心不自安。",
}

jiaojin:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaojin.name) and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("he"), function (id)
      local card = Fk:getCardById(id)
      return not card.is_damage_card and card.type ~= Card.TypeBasic and
        not player:prohibitDiscard(id)
    end)
    cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jiaojin.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#ol_ex__jiaojin-discard",
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:throwCard(event:getCostData(self).cards, jiaojin.name, player)
    if not player.dead and data.card and room:getCardArea(data.card) == Card.Processing then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, jiaojin.name, nil, true, player)
    end
  end,
})

return jiaojin
