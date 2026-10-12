local koulue = fk.CreateSkill {
  name = "kouluet",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kouluet"] = "寇掠",
  [":kouluet"] = "锁定技，你于摸牌阶段外获得的手牌不计入手牌上限且均视为【杀】。",

  ["@@kouluet_slash-inhand"] = "寇掠",

  ["$kouluet1"] = "掠其粟米，焚其城郭，使汉人闻我名丧胆！",
  ["$kouluet2"] = "血染黄沙，暴尸于野，此战必杀个痛快！",
}

koulue:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    return
      player.phase ~= Player.Draw and
      player:hasSkill(koulue.name) and
      table.find(data, function(move)
        return move.to == player and move.toArea == Card.PlayerHand
      end)
  end,
  on_use = function(self, event, target, player, data)
    table.forEach(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then
        table.forEach(move.moveInfo, function(info)
          player.room:setCardMark(Fk:getCardById(info.cardId), "@@kouluet_slash-inhand", 1)
        end)
      end
    end)

    player:filterHandcards()
  end,
})

koulue:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(koulue.name) and card:getMark("@@kouluet_slash-inhand") > 0
  end,
})

koulue:addEffect("filter", {
  card_filter = function(self, to_select, player)
    return
      player:hasSkill(koulue.name) and
      to_select:getMark("@@kouluet_slash-inhand") > 0 and
      table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("slash", to_select.suit, to_select.number)
    card.skillName = koulue.name
    return card
  end,
})

return koulue
