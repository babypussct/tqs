local mieji = fk.CreateSkill {
  name = "os_ex__mieji",
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable{
  ["os_ex__mieji"] = "灭计",
  [":os_ex__mieji"] = "出牌阶段限一次，你可以将一张黑色牌置于牌堆顶并选择一名有手牌的其他角色，"..
    "其选择：1.将一张与此牌类别相同的牌交给你；2.依次弃置两张与此牌类别不同的牌（不足则弃置一张）。",

  ["#os_ex__mieji-active"] = "灭计：选择一张黑色牌置于牌堆顶，并选择一名其他角色",
  ["#os_ex__mieji-choice"] = "灭计：选择交给%src一张%arg，或依次弃置两张非%arg",
  ["os_ex__mieji_handover"] = "交出一张%arg",
  ["os_ex__mieji_dis2card"] = "依次弃置两张非%arg",
  ["#os_ex__mieji-discard"] = "灭计：再选择一张非%arg弃置",

  ["$os_ex__mieji1"] = "我的计策，绝不留下一丝希望。",
  ["$os_ex__mieji2"] = "现在后悔已经太晚啦。",
}

mieji:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#os_ex__mieji-active",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 1,
  include_equip = true,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return card.color == Card.Black
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards > 0 and #selected == 0 and to_select ~= player and not to_select:isNude()
  end,
  on_use = function(self, room, use)
    local player = use.from
    local target = use.tos[1]
    room:moveCardTo(use.cards, Card.DrawPile, nil, fk.ReasonPut, mieji.name, nil, true, player)
    if target.dead then return end
    local card = Fk:getCardById(use.cards[1])
    local card_type = card.type
    local type_str = card:getTypeString()
    local ids = table.filter(target:getCardIds("he"), function (id)
      local c = Fk:getCardById(id)
      return c.type ~= card_type and not player:prohibitDiscard(c)
    end)
    local cards, choice = U.askForCardByMultiPatterns(
      target,
      {
        { ".|.|.|.|.|".. type_str, 1, 1, "os_ex__mieji_handover:::" .. type_str },
        { tostring(Exppattern{ id = ids }), 1, 1, "os_ex__mieji_dis2card:::" .. type_str }
      },
      mieji.name,
      false,
      "#os_ex__mieji-choice:" .. player.id .. ":" .. type_str
    )
    if choice:startsWith("os_ex__mieji_handover") then
      room:obtainCard(player, cards, true, fk.ReasonGive, target, mieji.name)
    elseif choice:startsWith("os_ex__mieji_dis2card") then
      room:throwCard(cards, mieji.name, target)
      if target.dead then return end
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = mieji.name,
        cancelable = false,
        pattern = ".|.|.|.|.|^" .. type_str,
        prompt = "#os_ex__mieji-discard:::" .. type_str,
      })
    end
  end,
})

return mieji
