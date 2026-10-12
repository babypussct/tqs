local chengqi = fk.CreateSkill{
  name = "chengqi",
}

Fk:loadTranslationTable{
  ["chengqi"] = "承启",
  [":chengqi"] = "你可以将至少两张手牌当一张你本回合未使用过的基本牌或普通锦囊牌使用，"..
  "你以此法使用的牌名字数不能大于用于转化的牌名字数之和，若相等，你令一名角色摸一张牌。",

  ["#chengqi"] = "承启：将至少两张手牌当一张牌使用（用于转化的字数不小于被转化牌的字数）",
  ["#chengqi-choose"] = "承启：令一名角色摸一张牌",

  ["$chengqi1"] = "世有十万字形，亦当有十万字体。",
  ["$chengqi2"] = "笔画如骨，不可拘于一形。",
}

chengqi:addEffect("viewas", {
  prompt = "#chengqi",
  pattern = ".",
  handly_pile = true,
  filter_pattern = {
    min_num = 2,
    max_num = math.huge,
    pattern = ".|.|.|^equip",
  },
  interaction_helper = function(self, player, selected_cards)
    local n = 0
    for _, id in ipairs(selected_cards) do
      n = n + Fk:getCardById(id):getNameLength(true)
    end
    local all_names = table.filter(Fk:getAllCardNames("bt"), function(name)
      return n >= Fk.all_card_types[name]:getNameLength(true)
    end)
    local names = player:getViewAsCardNames(chengqi.name, all_names, selected_cards, player:getTableMark("chengqi-turn"))
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards < 2 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, chengqi.name, cards)
  end,
  before_use = function(self, player, use)
    local n = use.card:getNameLength(true)
    for _, id in ipairs(use.card.subcards) do
      n = n - Fk:getCardById(id):getNameLength(true)
    end
    if n == 0 then
      use.extra_data = use.extra_data or {}
      use.extra_data.chengqi_draw = player
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #player:getViewAsCardNames(chengqi.name, Fk:getAllCardNames("bt"), nil, player:getTableMark("chengqi-turn")) > 0
  end,
  enabled_at_nullification = function(self, player, data)
    return #player:getHandlyIds() > 1 and self:enabledAtResponse(player, false)
  end
})
chengqi:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.chengqi_draw == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = chengqi.name,
      prompt = "#chengqi-choose",
      cancelable = false,
    })[1]
    to:drawCards(1, chengqi.name)
  end,
})
chengqi:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengqi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "chengqi-turn", data.card.trueName)
  end,
})

chengqi:addAcquireEffect(function(self, player, is_start)
  if not is_start and player.room.current == player then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(mark, use.card.trueName)
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "chengqi-turn", mark)
  end
end)

return chengqi
