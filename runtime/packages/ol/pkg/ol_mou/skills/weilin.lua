local weilin = fk.CreateSkill{
  name = "ol__weilin",
}

Fk:loadTranslationTable{
  ["ol__weilin"] = "威临",
  [":ol__weilin"] = "每回合限一次，你可以将一张牌当任意一种【杀】或【酒】使用。"..
  "此牌指定目标后，你令其所有与此牌颜色相同的手牌均视为【杀】直到回合结束。",

  ["#ol__weilin"] = "威临：将一张牌当任意属性的【杀】或【酒】使用",
  ["@ol__weilin-turn"] = "威临",

  ["$ol__weilin1"] = "汝等鼠辈，岂敢与某相抗！",
  ["$ol__weilin2"] = "义襄千里，威震华夏！",
}

weilin:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ol__weilin",
  pattern = "slash,analeptic",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  interaction_helper = function(self, player, selected_cards)
    local all_names = { "slash" }
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card.trueName == "slash" and not card.is_derived then
        table.insertIfNeed(all_names, card.name)
      end
    end
    table.insertIfNeed(all_names, "analeptic")
    return UI.CardNameBox {
      choices = player:getViewAsCardNames(weilin.name, all_names, selected_cards),
      all_choices = all_names,
    }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, weilin.name, cards)
  end,
  before_use = function(self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.ol__weilin = player
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(weilin.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(weilin.name) == 0
  end,
})
weilin:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ol__weilin == player and
      data.card.color ~= Card.NoColor and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local mark = data.to:getTableMark("@ol__weilin-turn")
    if table.insertIfNeed(mark, data.card:getColorString()) then
      player.room:setPlayerMark(data.to, "@ol__weilin-turn", mark)
      data.to:filterHandcards()
    end
  end,
})
weilin:addEffect("filter", {
  mute = true,
  card_filter = function(self, to_select, player)
    return table.contains(player:getCardIds("h"), to_select.id) and
      table.contains(player:getTableMark("@ol__weilin-turn"), to_select:getColorString())
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
})

return weilin
