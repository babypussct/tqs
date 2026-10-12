local boqia = fk.CreateSkill {
  name = "boqia",
}

Fk:loadTranslationTable {
  ["boqia"] = "博洽",
  [":boqia"] = "每回合限一次，你可以将三张牌当一张基本牌或非伤害普通锦囊牌使用，"..
  "若这三张牌的花色或类型均不同，此牌结算后你令一名角色将手牌调整至其体力上限，然后此技能可再次发动（每回合每种牌名限一次）。",

  ["#boqia"] = "博洽：将三张牌当一张基本牌或非伤害普通锦囊牌使用",
  ["#boqia-choose"] = "博洽：令一名角色将手牌调整至其体力上限",

  ["$boqia1"] = "夫金石丝竹之音，发自器而通于天。",
  ["$boqia2"] = "天下之理，虽万变而卒归乎中。",
}

boqia:addEffect("viewas", {
  prompt = "#boqia",
  max_turn_use_time = 1,
  pattern = ".",
  handly_pile = true,
  filter_pattern = {
    min_num = 3,
    max_num = 3,
    pattern = ".",
  },
  interaction_helper = function(self, player, selected_cards)
    local all_names, tricks = {}, {}
    for _, card in ipairs(Fk.cards) do
      if not table.contains(Fk:currentRoom().disabled_packs, card.package.name) and not card.is_derived then
        if card.type == Card.TypeBasic then
          table.insertIfNeed(all_names, card.name)
        elseif not card.is_damage_card and card:isCommonTrick() then
          table.insertIfNeed(tricks, card.name)
        end
      end
    end
    all_names = table.connect(all_names, tricks)
    local names = player:getViewAsCardNames(boqia.name, all_names, selected_cards, player:getTableMark("boqia-turn"))
    if #names > 0 then
      return UI.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 3 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, boqia.name, cards)
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "boqia-turn", use.card.trueName)
    local cards = use.card.subcards
    if #cards == 3 then
      local card1 = Fk:getCardById(cards[1], true)
      local card2 = Fk:getCardById(cards[2], true)
      local card3 = Fk:getCardById(cards[3], true)
      if (card1.type ~= card2.type and card2.type ~= card3.type and card3.type ~= card1.type) or
        (card1.suit ~= card2.suit and card2.suit ~= card3.suit and card3.suit ~= card1.suit) then
        use.extra_data = use.extra_data or {}
        use.extra_data.boqia = player
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
  enabled_at_nullification = function(self, player, data)
    return #player:getHandlyIds() + #player:getCardIds("e") > 2 and
      not table.contains(player:getTableMark("boqia-turn"), "nullification")
  end
}, { check_effect_limit = true })


boqia:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.boqia == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = boqia.name,
      prompt = "#boqia-choose",
      cancelable = false,
    })[1]
    local x = to:getHandcardNum() - to.maxHp
    if x > 0 then
      room:askToDiscard(to, {
        min_num = x,
        max_num = x,
        include_equip = false,
        skill_name = boqia.name,
        cancelable = false,
      })
    elseif x < 0 then
      to:drawCards(-x, boqia.name)
    end
    if not player.dead then
      player:clearSkillHistory(boqia.name)
    end
  end,
})

return boqia
