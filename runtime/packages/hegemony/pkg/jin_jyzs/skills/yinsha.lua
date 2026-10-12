local yinsha = fk.CreateSkill{
  name = "heg__yinsha",
}

Fk:loadTranslationTable {
  ["heg__yinsha"] = "引杀",
  [":heg__yinsha"] = "你可以将所有手牌当【借刀杀人】使用，此牌目标必须使用【杀】或将所有手牌当【杀】使用以响应此牌。",

  ["#heg__yinsha"] = "引杀：你可以将所有手牌当【借刀杀人】使用（需目标有武器）",
}

yinsha:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "collateral",
  prompt = "#heg__yinsha",
  handly_pile = true,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("collateral")
    card:addSubcards(player:getCardIds("h"))
    card.skillName = yinsha.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng()
  end,
})

yinsha:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(yinsha.name) and data.use and data.use.from == player and data.card.skillName == yinsha.name
  end,
  on_refresh = function(self, event, target, player, data)
    data:changeCardSkill("heg__yinsha_collateral_skill")
  end,
})

return yinsha