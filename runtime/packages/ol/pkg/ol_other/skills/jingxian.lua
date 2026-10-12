
local jingxian = fk.CreateSkill{
  name = "ol_le__jingxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_le__jingxian"] = "竞先",
  [":ol_le__jingxian"] = "锁定技，你使用牌后，手中【赤兔】向右奔跑一格，因此超越的牌视为【杀】。"..
  "每轮结束时，若【赤兔】在你手中最右侧，你执行一个额外回合。",

  ["@@ol_le__jingxian-inhand"] = "竞先",

  ["$ol_le__jingxian1"] = "无敌赤兔大人的传说就此开始！",
  ["$ol_le__jingxian2"] = "无论赛跑还是战斗，全都斗志满满！",
}

jingxian:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingxian.name) and
      table.contains(player:getCardIds("h"), player:getMark("fangma"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    local index = table.indexOf(cards, player:getMark("fangma"))
    if index < #cards then
      cards[index], cards[index + 1] = cards[index + 1], cards[index]
      room:setCardMark(Fk:getCardById(cards[index]), "@@ol_le__jingxian-inhand", 1)
      player.player_cards[Player.Hand] = cards
      room:syncPlayerClientCards(player)
      player:filterHandcards()
    end
  end,
})

jingxian:addEffect(fk.RoundEnd, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jingxian.name) and
      not player:isKongcheng() and player:getCardIds("h")[player:getHandcardNum()] == player:getMark("fangma")
  end,
  on_use = function (self, event, target, player, data)
    player:gainAnExtraTurn(false, jingxian.name)
  end,
})

jingxian:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@ol_le__jingxian-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return jingxian
