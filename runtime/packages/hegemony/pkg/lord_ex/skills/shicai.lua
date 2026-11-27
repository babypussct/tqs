
local shicai = fk.CreateSkill {
  name = "ld__shicai",
  max_branches_use_time = {
    ["basic"] = {
      [Player.HistoryPhase] = 1,
    },
    ["trick"] = {
      [Player.HistoryPhase] = 1,
    },
    ["equip"] = {
      [Player.HistoryPhase] = 1,
    },
  },
}

Fk:loadTranslationTable {
  ["ld__shicai"] = "恃才",
  [":ld__shicai"] = "出牌阶段每种类别限一次，你可以展示一张牌并交给一名没有手牌的其他角色，然后你摸两张牌。",

  ["#ld__shicai"] = "恃才：将一张牌交给一名没有手牌的角色，摸两张牌",

  ["$ld__shicai1"] = "吾才满腹，袁本初竟不从之。",
  ["$ld__shicai2"] = "阿瞒有我良计，取冀州便是易如反掌。",
}

shicai:addEffect("active", {
  anim_type = "support",
  prompt = "#ld__shicai",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return shicai:withinBranchTimesLimit(player, Fk:getCardById(to_select):getTypeString(), Player.HistoryPhase)
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select:isKongcheng() and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:addSkillBranchUseHistory(shicai.name, Fk:getCardById(effect.cards[1]):getTypeString(), 1)
    room:moveCardTo(effect.cards, Card.PlayerHand, effect.tos[1], fk.ReasonGive, shicai.name, nil, true, player)
    if not player.dead then
      player:drawCards(2, shicai.name)
    end
  end,
})

return shicai
