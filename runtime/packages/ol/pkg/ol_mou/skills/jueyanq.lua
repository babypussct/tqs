local jueyanq = fk.CreateSkill{
  name = "jueyanq",
  max_branches_use_time = {
    ["trick"] = {
      [Player.HistoryRound] = 1
    },
    ["basic"] = {
      [Player.HistoryRound] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["jueyanq"] = "绝颜",
  [":jueyanq"] = "每轮各限一次，当你需要使用手牌中一张普通锦囊牌或红色基本牌时，可改为展示并视为使用之。"..
  "你每轮首次展示一种花色的手牌后摸一张牌。",

  ["#jueyanq"] = "绝颜：展示一张普通锦囊牌或红色基本牌，视为使用之",

  ["$jueyanq1"] = "半抹胭脂失颜色，一点蛾眉冠群生。",
  ["$jueyanq2"] = "朱颜倾世，绝骨法用笔，教乐府暗哑。",
}

jueyanq:addEffect("viewas", {
  pattern = ".",
  prompt = "#jueyanq",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getCardIds("h"), to_select) then
      local card = Fk:getCardById(to_select)
      return (card:isCommonTrick() or (card.type == Card.TypeBasic and card.color == Card.Red)) and
        jueyanq:withinBranchTimesLimit(player, card:getTypeString(), Player.HistoryRound)
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Fk:getCardById(cards[1]).name)
    card.skillName = jueyanq.name
    card:addFakeSubcards(cards)
    return card
  end,
  history_branch = function(self, player, data)
    local card = Fk:getCardById(data.cards[1])
    return card:getTypeString()
  end,
  before_use = function (self, player, use)
    player:showCards(use.card.fake_subcards)
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
  enabled_at_nullification = Util.FalseFunc, --不额外产生无懈读条
}, { check_skill_limit = true })

jueyanq:addEffect(fk.CardShown, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jueyanq.name) and
      table.find(data.cardIds, function (id)
        return table.contains(player:getCardIds("h"), id) and
          not table.contains(player:getTableMark("jueyanq-round"), Fk:getCardById(id).suit) and
          Fk:getCardById(id).suit ~= Card.NoSuit
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local suits = player:getTableMark("jueyanq-round")
    local n = 0
    for _, id in ipairs(data.cardIds) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and table.insertIfNeed(suits, Fk:getCardById(id).suit) then
        n = n + 1
      end
    end
    player.room:setPlayerMark(player, "jueyanq-round", suits)
    player:drawCards(n, jueyanq.name)
  end,
})

return jueyanq
