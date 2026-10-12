local jianying = fk.CreateSkill {
  name = "os_ex__jianying",
}

Fk:loadTranslationTable {
  ["os_ex__jianying"] = "渐营",
  [":os_ex__jianying"] = "当你使用牌时，若此牌与你使用的上一张牌点数或花色相同，你可以摸一张牌。" ..
      "每回合限一次，你可以将一张牌当你使用的上一张非装备牌使用（无次数限制；若你于此阶段内使用的上一张牌有花色，此牌花色视为上一张牌的花色）。" ..
      "你使用与上一张同花色的牌无次数限制且不计入次数，与上一张同点数的牌无距离限制。",

  ["#os_ex__jianying-active"] = "渐营：将一张牌当 %arg 使用",
  ["#os_ex__jianying-active_suit"] = "渐营：将一张牌当 %arg （%arg2） 使用",
  ["@os_ex__jianying_record"] = "渐营",

  ["$os_ex__jianying1"] = "缓而耗之，曹军自乱。",
  ["$os_ex__jianying2"] = "徐以攻敌，缓图天下。",
}

local U = require "packages.utility.utility"

jianying:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic,trick",
  max_phase_use_time = 1,
  prompt = function(self, player)
    local name = player:getMark("os_ex__jianying_name")
    local suit = player:getMark("os_ex__jianying_suit-phase")
    if suit ~= 0 and suit ~= Card.NoSuit then
      return "#os_ex__jianying-active_suit:::" .. name .. ":" .. U.ConvertSuit(suit, "int", "sym")
    end
    return "#os_ex__jianying-active:::" .. name
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(player:getMark("os_ex__jianying_name"), nil, nil, jianying.name, cards)
    local suit = player:getMark("os_ex__jianying_suit-phase")
    if suit ~= 0 and suit ~= Card.NoSuit then
      card.suit = suit
      card.color = 2 - suit % 2
    end
    return card
  end,
  enabled_at_play = function (self, player)
    if player:getMark("os_ex__jianying_name") == 0 then return false end
    local card = Fk:cloneCard(player:getMark("os_ex__jianying_name"), nil, nil, jianying.name)
    if Fk.currentResponsePattern == nil then
      return player:canUse(card)
    else
      return Exppattern:Parse(Fk.currentResponsePattern):match(card)
    end
  end,
  enabled_at_response = function (self, player, response)
    if response or player:getMark("os_ex__jianying_name") == 0 then return false end
    local card = Fk:cloneCard(player:getMark("os_ex__jianying_name"), nil, nil, jianying.name)
    if Fk.currentResponsePattern == nil then
      return player:canUse(card)
    else
      return Exppattern:Parse(Fk.currentResponsePattern):match(card)
    end
  end
}, { check_effect_limit = true })

jianying:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(jianying.name) and
      data.card.suit == player:getMark("os_ex__jianying_suit")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

jianying:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(jianying.name) and
        (data.extra_data or {}).os_ex__jianying_triggerable
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jianying.name)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianying.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.suit == player:getMark("os_ex__jianying_suit") or (data.card.number == player:getMark("os_ex__jianying_number") and data.card.number ~= 0) then
      data.extra_data = data.extra_data or {}
      data.extra_data.os_ex__jianying_triggerable = true
    end
    room:setPlayerMark(player, "os_ex__jianying_suit",
      data.card.suit == Card.NoSuit and 0 or data.card.suit)
    room:setPlayerMark(player, "os_ex__jianying_suit-phase", data.card.suit)
    room:setPlayerMark(player, "os_ex__jianying_number", data.card.number)
    local record = player:getTableMark("@os_ex__jianying_record")
    record[1] = data.card:getSuitString(true)
    record[2] = data.card:getNumberStr()
    if data.card.type ~= Card.TypeEquip then
      room:setPlayerMark(player, "os_ex__jianying_name", data.card.name)
      record[3] = data.card.name
    end
    room:setPlayerMark(player, "@os_ex__jianying_record", record)
  end,
})

jianying:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(jianying.name) and card and card.number == player:getMark("os_ex__jianying_number") and card.number ~= 0
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(jianying.name) and card and (table.contains(card.skillNames, jianying.name) or card.suit == player:getMark("os_ex__jianying_suit"))
  end
})

jianying:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "os_ex__jianying_suit", 0)
  room:setPlayerMark(player, "os_ex__jianying_number", 0)
  room:setPlayerMark(player, "os_ex__jianying_name", 0)
  room:setPlayerMark(player, "@os_ex__jianying_record", 0)
end)

return jianying
