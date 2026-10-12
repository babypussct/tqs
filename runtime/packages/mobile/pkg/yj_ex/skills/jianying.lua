local jianying = fk.CreateSkill {
  name = "m_ex__jianying",
}

Fk:loadTranslationTable{
  ["m_ex__jianying"] = "渐营",
  [":m_ex__jianying"] = "当你于出牌阶段内使用牌时，若此牌与你于此阶段内使用的上一张牌点数或花色相同，你可以摸一张牌。"..
    "出牌阶段限一次，你可以将一张牌当任意一种基本牌使用，若你于此阶段内使用的上一张牌有花色，则此牌花色视为你本回合使用的上一张牌的花色。",

  ["#m_ex__jianying-active"] = "渐营：将一张牌转化为任意基本牌使用",
  ["@m_ex__jianying_record-phase"] = "渐营",

  ["$m_ex__jianying1"] = "良谋百出，渐定决战胜势！",
  ["$m_ex__jianying2"] = "佳策数成，破敌垂手可得！",
}

jianying:addEffect("viewas", {
  max_phase_use_time = 1,
  prompt = "#m_ex__jianying-active",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    return UI.CardNameBox {
      choices = player:getViewAsCardNames(jianying.name, all_names),
      all_choices = all_names,
    }
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    if Fk.all_card_types[self.interaction.data] == nil or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)

    local suitstrings = {"spade", "heart", "club", "diamond"}
    local suits = {Card.Spade, Card.Heart, Card.Club, Card.Diamond}
    local colors = {Card.Black, Card.Red, Card.Black, Card.Red}
    local suit = player:getMark("m_ex__jianying_suit-phase")
    if table.contains(suitstrings, suit) then
      card.suit = suits[table.indexOf(suitstrings, suit)]
      card.color = colors[table.indexOf(suitstrings, suit)]
    end

    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "m_ex__jianying_used-phase", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("m_ex__jianying_used-phase") == 0
  end,
})

jianying:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player.phase == Player.Play and
      (data.extra_data or {}).m_ex__jianying_triggerable and player:hasSkill(jianying.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jianying.name)
  end,
})

jianying:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianying.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString() == player:getMark("m_ex__jianying_suit-phase") or
        (data.card.number == player:getMark("m_ex__jianying_number-phase") and data.card.number ~= 0) then
      data.extra_data = data.extra_data or {}
      data.extra_data.m_ex__jianying_triggerable = true
    end
    if data.card.suit == Card.NoSuit then
      room:setPlayerMark(player, "m_ex__jianying_suit-phase", 0)
    else
      room:setPlayerMark(player, "m_ex__jianying_suit-phase", data.card:getSuitString())
    end
    room:setPlayerMark(player, "m_ex__jianying_number-phase", data.card.number)
    room:setPlayerMark(player, "@m_ex__jianying_record-phase", {data.card:getSuitString(true), data.card:getNumberStr()})
  end,
})

jianying:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "m_ex__jianying_used-phase", 0)
  room:setPlayerMark(player, "m_ex__jianying_suit-phase", 0)
  room:setPlayerMark(player, "m_ex__jianying_number-phase", 0)
  room:setPlayerMark(player, "@m_ex__jianying_record-phase", 0)
end)

local AI = Fk.Ltk.AI
jianying:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return jianying
