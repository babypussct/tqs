
local boxue = fk.CreateSkill {
  name = "boxue",
}

Fk:loadTranslationTable{
  ["boxue"] = "博学",
  [":boxue"] = "每轮限一次，你可以弃置所有弃牌堆中有的手牌，视为使用一张弃牌堆中没有且能够指定目标的基本牌或普通锦囊牌。",

  ["#boxue"] = "博学：弃置所有弃牌堆中有的手牌，视为使用一张基本牌或普通锦囊牌",
  ["Will Discard"] = "将弃置",

  ["$boxue1"] = "五年读书，三年勤习，年少亦为博士！",
  ["$boxue2"] = "何须经难历险，书中自有天地。"
}

boxue:addEffect("viewas", {
  pattern = ".",
  prompt = "#boxue",
  filter_pattern = {
    max_num = 99, -- 显示弃牌提示，点击确认后再进入选牌名
    min_num = 0,
    pattern = ".",
    skill_name = boxue.name,
  },
  interaction_helper = function(self, player, selected_cards, selected_targets, extra_data)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(boxue.name, all_names)
    for _, id in ipairs(Fk:currentRoom().discard_pile) do
      table.removeOne(names, Fk:getCardById(id).name)
    end
    names = table.filter(names, function (name)
      return not Fk:cloneCard(name).is_passive
    end)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if Fk.all_card_types[self.interaction.data] == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, boxue.name)
  end,
  card_tip = function (self, player, to_select, selected, selected_targets, card, selectable, extra_data)
    local names = {}
    table.forEach(Fk:currentRoom().discard_pile, function (id) table.insertIfNeed(names, Fk:getCardById(id).trueName) end)
    if not player:prohibitDiscard(to_select) and table.contains(names, Fk:getCardById(to_select).trueName) then
      return "Will Discard"
    end
  end,
  before_use = function (self, player, use)
    local room = player.room
    local names = {}
    table.forEach(room.discard_pile, function (id) table.insertIfNeed(names, Fk:getCardById(id).trueName) end)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id) and table.contains(names, Fk:getCardById(id).trueName) -- 实际结算如此
    end)
    room:throwCard(cards, boxue.name, player, player)
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(boxue.name, Player.HistoryRound) == 0 then
      local names = {}
      table.forEach(Fk:currentRoom().discard_pile, function (id) table.insertIfNeed(names, Fk:getCardById(id).trueName) end)
      return not not table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id) and table.contains(names, Fk:getCardById(id).trueName)
      end)
    end
  end,
  enabled_at_response = function (self, player, response)
    if not response and player:usedSkillTimes(boxue.name, Player.HistoryRound) == 0 then
      local names = {}
      table.forEach(Fk:currentRoom().discard_pile, function (id) table.insertIfNeed(names, Fk:getCardById(id).trueName) end)
      return not not table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id) and table.contains(names, Fk:getCardById(id).trueName)
      end)
    end
  end,
  enabled_at_nullification = Util.FalseFunc,
})

return boxue
