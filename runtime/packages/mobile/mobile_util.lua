---@class mobileUtil : Object
---@field public changeRhyme fun(room: Room, player: ServerPlayer, skillName: string, scope?: integer)
local mobileUtil = {}

-- 判断卡牌是否已明置
---@param room Room | AbstractRoom
---@param card Card | integer
---@return boolean
mobileUtil.cardIsVisible = function(room, card)
  if type(card) == "number" then
    card = Fk:getCardById(card)
  end

  return
    table.contains({ Card.PlayerEquip, Card.PlayerJudge }, room:getCardArea(card)) or
    card:getMark("@@mobile_visible_card-inarea") ~= 0
end
Fk:loadTranslationTable{
  ["@@mobile_visible_card-inarea"] = "明置",
}

--- DisplayCardDataSpec 明置牌数据
---@class DisplayCardDataSpec
---@field public who ServerPlayer @ 明置牌的角色
---@field public cards Card[] @ 明置的卡牌

---@class mobileUtil.DisplayCardData: DisplayCardDataSpec, TriggerData
mobileUtil.DisplayCardData = TriggerData:subclass("DisplayCardData")

--- 明置牌 TriggerEvent
---@class mobileUtil.DisplayCardTE: TriggerEvent
---@field public data mobileUtil.DisplayCardData
mobileUtil.DisplayCardTE = TriggerEvent:subclass("DisplayCardEvent")

--- 牌明置后
---@class mobileUtil.CardDisplayed: mobileUtil.DisplayCardTE
mobileUtil.CardDisplayed = mobileUtil.DisplayCardTE:subclass("mobileUtil.CardDisplayed")

---@alias DisplayCardTrigFunc fun(self: TriggerSkill, event: mobileUtil.DisplayCardTE,
---  target: ServerPlayer, player: ServerPlayer, data: mobileUtil.DisplayCardData):any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: mobileUtil.DisplayCardTE,
---  data: TrigSkelSpec<DisplayCardTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton

--- 牌明置后 GameEvent
mobileUtil.DisplayCardEvent = "DisplayCard"

mobileUtil.CardDisplayedMark = "@@mobile_visible_card-inarea"

Fk:addGameEvent(mobileUtil.DisplayCardEvent, nil, function (self)
  local DisplayCardData = self.data ---@class DisplayCardDataSpec
  local room = self.room ---@type Room
  local who = DisplayCardData.who
  local cards = DisplayCardData.cards

  local toDisplay = table.filter(cards, function(card)
    return
      table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }, room:getCardArea(card)) and
      not mobileUtil.cardIsVisible(room, card)
  end)
  if #toDisplay == 0 then
    return false
  end

  table.forEach(toDisplay, function(card)
    room:setCardMark(card, "@@mobile_visible_card-inarea", { room:getCardArea(card) })
  end)

  room.logic:trigger(mobileUtil.CardDisplayed, who, DisplayCardData)
end)

--- 加减谋略值
---@param player ServerPlayer @ 角色
---@param cards integer[] | Card[] @ 即将明置的牌
---@return mobileUtil.DisplayCardData?
mobileUtil.displayCards = function(player, cards)
  if type(cards[1]) == "number" then
    cards = table.map(cards, function(id) return Fk:getCardById(id) end)
  end

  local toDisplay = table.filter(cards, function(card)
    return
      table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }, player.room:getCardArea(card)) and
      not mobileUtil.cardIsVisible(player.room, card)
  end)
  if #toDisplay == 0 then
    return
  end

  local DisplayCardData = mobileUtil.DisplayCardData:new{
    who = player,
    cards = cards,
  }
  local event = GameEvent[mobileUtil.DisplayCardEvent]:create(DisplayCardData)
  local _, ret = event:exec()
  return DisplayCardData
end
Fk:loadTranslationTable{
  ["#DisplayCardsDesc"] = "明置是一种行为，是指将游戏牌由背面向上翻转为正面向上的过程。<br />" ..
  "当一名角色明置牌时，所有即将被明置的牌均必须符合以下条件：<br />" ..
  "1.在一名角色的区域里；<br />" ..
  "2.不能是明置牌。<br />" ..
  "（注：此机制不额外适配除手杀明置之外的机制）",

  ["#CardDisplayedDesc"] = "明置牌是一种游戏牌的通用属性，指的是此牌对所有玩家可见。<br />" ..
  "在通常情况下，一名角色装备区和判定区里的牌都是明置牌，但一名角色的明置牌不包括其判定区里的牌。<br />" ..
  "（注：此机制不额外适配除手杀明置之外的机制）",
}

-- 一名角色是否有明置牌
---@param room Room | AbstractRoom
---@param player Player
---@param includeJudge? boolean
---@return boolean
mobileUtil.hasCardsDisplayed = function(room, player, includeJudge)
  return
    table.find(player:getCardIds("h"), function(id)
      return mobileUtil.cardIsVisible(room, id)
    end) ~= nil or
    #player:getCardIds("e") > 0 or
    (includeJudge == true and #player:getCardIds("j") > 0)
end

return mobileUtil
