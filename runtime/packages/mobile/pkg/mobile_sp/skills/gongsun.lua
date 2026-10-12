local gongsun = fk.CreateSkill{
  name = "mobile__gongsun",
}

Fk:loadTranslationTable{
  ["mobile__gongsun"] = "共损",
  [":mobile__gongsun"] = "出牌阶段开始时，你可以弃置两张牌并选择一名其他角色，然后你声明一种基本牌或普通锦囊牌的牌名。"..
  "若如此做，直到你的下个回合开始或你死亡时，你与其均不能使用、打出或弃置此牌名的手牌。",

  ["#mobile__gongsun-choose"] = "共损：弃置两张牌并选择一名其他角色，声明一个牌名，双方不能使用、打出、弃置此手牌",
  ["#mobile__gongsun-name"] = "共损：选择牌名，你和 %dest 无法使用、打出、弃置此手牌直到你下个回合开始",
  ["@mobile__gongsun"] = "共损",

  ["$mobile__gongsun1"] = "胸怀大才者，岂能与庸人共处？",
  ["$mobile__gongsun2"] = "满朝文武，半数庶子而已。",
}

local U = require "packages.utility.utility"

gongsun:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongsun.name) and player.phase == Player.Play and
      #player:getCardIds("he") > 1 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 2,
      max_card_num = 2,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = gongsun.name,
      prompt = "#mobile__gongsun-choose",
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards == 2 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, gongsun.name, player, player)
    local names = Fk:getAllCardNames("bt", true)
    if player.dead or #names == 0 or to.dead then return end
    local choice = U.askForChooseCardNames(room, player, names, 1, 1, gongsun.name, "#mobile__gongsun-name::"..to.id)[1]
    room:addTableMarkIfNeed(player, "_mobile__gongsun", to.id)
    for _, p in ipairs({player, to}) do
      room:addTableMark(p, "@mobile__gongsun", choice)
    end
  end,
})
gongsun:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("@mobile__gongsun")
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.contains(mark, card.trueName) and
      table.every(cards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getTableMark("@mobile__gongsun")
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.contains(mark, card.trueName) and
      table.every(cards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
  end,
  prohibit_discard = function(self, player, card)
    local mark = player:getTableMark("@mobile__gongsun")
    return table.contains(mark, card.trueName) and table.contains(player:getCardIds("h"), card.id)
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_mobile__gongsun") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@mobile__gongsun", 0)
    for _, id in ipairs(player:getMark("_mobile__gongsun")) do
      local p = room:getPlayerById(id)
      room:setPlayerMark(p, "@mobile__gongsun", 0)
    end
  end,
}
gongsun:addEffect(fk.TurnStart, spec)
gongsun:addEffect(fk.Death, spec)

return gongsun
