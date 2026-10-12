local liezhiz = fk.CreateSkill {
  name = "liezhiz",
}

Fk:loadTranslationTable{
  ["liezhiz"] = "烈志",
  [":liezhiz"] = "每回合限一次，你可以减1点体力上限，视为使用一张【桃】或不计入次数且无次数限制的【酒】。",

  ["#liezhiz"] = "烈志：减1点体力上限，视为使用【桃】或【酒】",

  ["$liezhiz1"] = "今王室将危，贼臣未枭，此诚报恩效命之秋也。",
  ["$liezhiz2"] = "汉室不幸，皇纲失统，今当纠合义兵，共赴国难。",
}

liezhiz:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach,analeptic",
  prompt = "#liezhiz",
  interaction = function(self, player)
    local all_names = { "peach", "analeptic" }
    local extraData = {}
    if
      ClientInstance and
      ClientInstance.current_request_handler and
      ClientInstance.current_request_handler.extra_data
    then
      extraData = ClientInstance.current_request_handler.extra_data
    end

    extraData.bypass_times = true

    local names = player:getViewAsCardNames(liezhiz.name, all_names, nil, nil, extraData)
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {},
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = liezhiz.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:changeMaxHp(player, -1)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(liezhiz.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function (self, player, response)
    return not response and player:usedSkillTimes(liezhiz.name, Player.HistoryTurn) == 0
  end,
})

liezhiz:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, liezhiz.name)
  end,
})

return liezhiz
