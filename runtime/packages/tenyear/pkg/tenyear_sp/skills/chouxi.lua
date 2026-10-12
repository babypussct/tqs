local chouxi = fk.CreateSkill {
  name = "chouxi",
}

Fk:loadTranslationTable{
  ["chouxi"] = "筹汐",
  [":chouxi"] = "出牌阶段，你可以将一张牌当场上“溟”里的一张无距离和次数限制的基本牌或普通锦囊牌使用（每种牌名每回合限一次）。",

  ["#chouxi-viewas"] = "筹汐：你可将一张手牌当其中一种牌使用（无距离和次数限制，且每种牌名每回合限一次）",

  ["$chouxi1"] = "此间云雨，皆出我袖！",
  ["$chouxi2"] = "江表涛声。尽言吴音龙语。",
}

chouxi:addEffect("viewas", {
  prompt = "#chouxi-viewas",
  pattern = ".",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  interaction_helper = function(self, player, selected_cards)
    local names = {}
    table.forEach(Fk:currentRoom().alive_players, function(p)
      table.forEach(p:getPile("$cangming_ming"), function(id)
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic or card:isCommonTrick() then
          table.insertIfNeed(names, card.name)
        end
      end)
    end)

    names = player:getViewAsCardNames(
      chouxi.name,
      names,
      selected_cards,
      player:getTableMark("chouxi_used-turn"),
      { bypass_distances = true, bypass_times = true }
    )
    if #names == 0 then
      return
    end

    return UI.CardNameBox { choices = names }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil or #cards ~= 1 then
      return
    end
    return Fk:cloneCard(self.interaction.data, nil, nil, chouxi.name, cards)
  end,
  before_use = function(self, player, use)
    player.room:addTableMarkIfNeed(player, "chouxi_used-turn", use.card.trueName)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p) return #p:getPile("$cangming_ming") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return false
  end,
})

chouxi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, chouxi.name)
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, chouxi.name)
  end,
})

chouxi:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "chouxi_used-turn", 0)
end)

return chouxi
