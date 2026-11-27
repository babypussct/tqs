
local chenglue = fk.CreateSkill {
  name = "ld__chenglue",
}

Fk:loadTranslationTable {
  ["ld__chenglue"] = "成略",
  [":ld__chenglue"] = "你可以将基本牌当【火攻】使用，造成伤害后，目标弃置因此展示的牌。",

  ["#ld__chenglue"] = "成略：将基本牌当【火攻】使用，造成伤害则目标弃置展示牌",

  ["$ld__chenglue1"] = "阿瞒，苦思之事，我早有良策。",
  ["$ld__chenglue2"] = "策略已有，按部就班即可得胜。",
}

chenglue:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#ld__chenglue",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|basic",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = chenglue.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

chenglue:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if data.to == player and
      data.card and table.contains(data.card.skillNames, chenglue.name) and not data.chain then
      local effect_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if effect_event and effect_event.data.to == player then
        local card = (effect_event.data.extra_data or {}).fire_attack_show
        if card then
          card = table.filter(card, function (id)
            return table.contains(player:getCardIds("he"), id) and not player:prohibitDiscard(id)
          end)
          event:setCostData(self, { cards = card })
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, chenglue.name, player, player)
  end,
})

return chenglue
