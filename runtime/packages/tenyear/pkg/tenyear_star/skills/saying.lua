local saying = fk.CreateSkill {
  name = "saying",
}

Fk:loadTranslationTable{
  ["saying"] = "飒影",
  [":saying"] = "每轮每种牌名限一次，当你需要使用【杀】或【闪】时，你可以使用一张装备牌，然后视为使用之；当你需要使用【桃】或【酒】时，"..
  "你可以收回装备区里的一张牌，然后视为使用之。",

  ["#saying1"] = "飒影：使用%arg，然后视为使用【杀】或【闪】",
  ["#saying2"] = "飒影：收回%arg，然后视为使用【桃】或【酒】",
  ["#saying-nil"] = "飒影：选择一张装备牌",

  ["$saying1"] = "倩影映江汀，巾帼犹飒爽！",
  ["$saying2"] = "我有一袭红袖，欲揾英雄泪！"
}

saying:addEffect("viewas", {
  pattern = "slash,jink,peach,analeptic",
  prompt = function(self, player, selected_cards)
    if #selected_cards == 0 then
      return "#saying-nil"
    else
      local card = Fk:getCardById(selected_cards[1])
      if table.contains(player:getCardIds("e"), selected_cards[1]) then
        return "#saying2:::"..card:toLogString()
      else
        return "#saying1:::"..card:toLogString()
      end
    end
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = "",
    subcards = {}
  },
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if table.contains(player:getCardIds("e"), to_select) then
        return true
      else
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip and player:canUseTo(card, player)
      end
    end
  end,
  interaction_helper = function(self, player, selected_cards)
    if #selected_cards == 0 then return end
    local all_names = { }
    if table.contains(player:getCardIds("e"), selected_cards[1]) then
      all_names = { "peach", "analeptic" }
    else
      all_names = { "slash" }
      for _, card in ipairs(Fk.cards) do
        if not table.contains(Fk:currentRoom().disabled_packs, card.package.name) and not card.is_derived then
          if card.trueName == "slash" then
            table.insertIfNeed(all_names, card.name)
          end
        end
      end
      table.insert(all_names, "jink")
    end
    local names = player:getViewAsCardNames(saying.name, all_names, {}, player:getTableMark("saying-round"))
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards == 0 then return nil end
    local card = Fk:cloneCard(self.interaction.data, nil, nil, saying.name)
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "saying-round", use.card.trueName)
    local id = use.card.fake_subcards[1]
    if use.card.trueName == "slash" or use.card.trueName == "jink" then
      room:useCard{
        from = player,
        tos = { player },
        card = Fk:getCardById(id),
      }
    elseif use.card.trueName == "peach" or use.card.trueName == "analeptic" then
      room:obtainCard(player, id, true, fk.ReasonJustMove, player, saying.name)
    end
  end,
  enabled_at_play = function(self, player)
    local names = player:getViewAsCardNames(saying.name, {"slash", "jink", "peach", "analeptic"}, nil, player:getTableMark("saying-round"))
    if #names == 0 then return end
    if (table.contains(names, "slash") or table.contains(names, "jink")) and #player:getHandlyIds() > 0 then
      return true
    end
    if (table.contains(names, "peach") or table.contains(names, "analeptic")) and #player:getCardIds("e") > 0 then
      return true
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return end
    local names = player:getViewAsCardNames(saying.name, {"slash", "jink", "peach", "analeptic"}, nil, player:getTableMark("saying-round"))
    if #names == 0 then return end
    if (table.contains(names, "slash") or table.contains(names, "jink")) and #player:getHandlyIds() > 0 then
      return true
    end
    if (table.contains(names, "peach") or table.contains(names, "analeptic")) and #player:getCardIds("e") > 0 then
      return true
    end
  end,
})

return saying
