local hanhong = fk.CreateSkill {
  name = "os__hanhong",
}

Fk:loadTranslationTable{
  ["os__hanhong"] = "翰鸿",
  [":os__hanhong"] = "出牌阶段每种花色限一次或受到伤害后，你可以声明一种花色并弃置X张牌（X为你手牌中花色最多的牌数），观看牌堆顶前X张你声明花色的牌，"..
  "获得其中至多两张牌。若你弃置了♣牌，你摸一张牌。",

  ["#os__hanhong"] = "翰鸿：声明一种花色，弃置%arg张牌，从牌堆获得至多两张此花色的牌",
  ["#os__hanhong-invoke"] = "你可发动“翰鸿”，声明一种花色，弃置%arg张牌，从牌堆获得至多两张此花色的牌",
  ["#os__hanhong-discard"] = "你可发动“翰鸿”，弃置%arg张牌，从牌堆获得至多两张%arg2牌",
  ["#os__hanhong-prey"] = "翰鸿：获得其中至多两张牌",
  ["@os__hanhong-phase"] = "翰鸿",

  ["$os__hanhong1"] = "鸿雁携诗去，天地入怀来！",
  ["$os__hanhong2"] = "正合凌霄瀚，弃梅引凤彰！",
}

local hanhongCount = function (player)
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        suits[suit] = (suits[suit] or 0) + 1
      end
    end
    local max = 0
    for _, num in pairs(suits) do
      if num > max then
        max = num
      end
    end
    return max
end

local doHanhong = function (room, player, suit, cards)
  room:sendLog{
    type = "#Choice",
    from = player.id,
    arg = suit,
    toast = true,
  }
  local yes = table.find(cards, function (id)
    return Fk:getCardById(id).suit == Card.Club
  end)
  room:throwCard(cards, hanhong.name, player, player)
  if player.dead then return end
  local c = {}
  for _, id in ipairs(room.draw_pile) do
    if Fk:getCardById(id):getSuitString(true) == suit then
      table.insert(c, id)
      if #c == #cards then
        break
      end
    end
  end
  if #c > 0 then
    local card = room:askToChooseCards(player, {
      target = player,
      flag = { card_data = {{ "toObtain", c }} },
      skill_name = hanhong.name,
      min = 1,
      max = 2,
      prompt = "#os__hanhong-prey",
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, hanhong.name, nil, false, player)
    if player.dead then return end
  end
  if yes then
    player:drawCards(1, hanhong.name)
  end
end

hanhong:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#os__hanhong:::"..hanhongCount(player)
  end,
  card_num = function (self, player)
    return hanhongCount(player)
  end,
  target_num = 0,
  interaction = function (self, player)
    local all_choices = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choices = table.filter(all_choices, function (choice)
      return not table.contains(player:getTableMark("@os__hanhong-phase"), choice)
    end)
    if #choices == 0 then return end
    return UI.OptionBox { options = choices, all_options = all_choices }
  end,
  can_use = function(self, player)
    return hanhongCount(player) > 0 and #player:getTableMark("@os__hanhong-phase") < 4
  end,
  card_filter = function (self, player, to_select, selected)
    return self.interaction.data ~= nil and #selected < hanhongCount(player) and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local suit = self.interaction.data
    room:addTableMark(player, "@os__hanhong-phase", suit)
    doHanhong(player.room, player, suit, effect.cards)
  end,
})

hanhong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local num = hanhongCount(player)
    local choice = room:askToChoice(player, {
      choices = {"log_spade", "log_club", "log_heart", "log_diamond", "Cancel"},
      skill_name = hanhong.name,
      prompt = "#os__hanhong-invoke:::" .. num,
    })
    if choice ~= "Cancel" then
      local cards = room:askToDiscard(player, {
        min_num = num,
        max_num = num,
        skill_name = hanhong.name,
        skip = true,
        prompt = "#os__hanhong-discard:::" .. num .. ":" .. choice,
      })
      if #cards > 0 then
        event:setCostData(self, {suit = choice, cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    doHanhong(player.room, player, event:getCostData(self).suit, event:getCostData(self).cards)
  end
})

hanhong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@os__hanhong-phase", 0)
end)

return hanhong
