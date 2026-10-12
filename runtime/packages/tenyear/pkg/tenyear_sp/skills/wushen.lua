
local wushen = fk.CreateSkill {
  name = "ty__wushen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__wushen"] = "武神",
  [":ty__wushen"] = "锁定技，你的<font color='red'>♥</font>手牌视为【杀】；"..
  "你使用<font color='red'>♥</font>【杀】无距离和次数限制，且造成伤害后你摸一张牌。",

  ["$ty__wushen1"] = "",
  ["$ty__wushen2"] = "",
}

wushen:addEffect("filter", {
  card_filter = function(self, to_select, player)
    return player:hasSkill(wushen.name) and to_select.suit == Card.Heart and
      table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = wushen.name
    return card
  end,
})

wushen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(wushen.name) and card:matchVSPattern("slash|.|heart")
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(wushen.name) and card:matchVSPattern("slash|.|heart")
  end,
})

wushen:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wushen.name) and
      data.card and data.card.trueName == "slash" and data.card.suit == Card.Heart
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, wushen.name)
  end,
})

return wushen
