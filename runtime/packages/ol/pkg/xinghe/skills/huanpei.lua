local huanpei = fk.CreateSkill {
  name = "huanpei",
}

Fk:loadTranslationTable{
  ["huanpei"] = "环佩",
  [":huanpei"] = "每轮限一次，当你需要使用基本牌时，你可将手牌数调整至与体力值相同，视为使用此牌。",

  ["#huanpei"] = "环佩：将手牌数调整至与体力值相同，视为使用一张基本牌",

  ["$huanpei1"] = "解佩以邀，请君静聆。",
  ["$huanpei2"] = "玉振清音，步步生莲。",
}

huanpei:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#huanpei",
  filter_pattern = function(self, player)
    local x = math.max(0, player:getHandcardNum() - player.hp)
    return {
      min_num = x,
      max_num = x,
      pattern = "",
      subcards = {}
    }
  end,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(huanpei.name, all_names)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getHandcardNum() - player.hp and
      table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local x = player:getHandcardNum() - player.hp
    if x > 0 and #cards ~= x then
      return
    end
    local card = Fk:cloneCard(self.interaction.data, nil, nil, huanpei.name)
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    local cards = use.card.fake_subcards
    if #cards > 0 then
      player.room:throwCard(use.card.fake_subcards, huanpei.name, player, player)
    else
      local x = player.hp - player:getHandcardNum()
      if x > 0 then
        player:drawCards(x, huanpei.name)
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(huanpei.name, Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(huanpei.name, Player.HistoryRound) == 0
  end,
})

return huanpei
