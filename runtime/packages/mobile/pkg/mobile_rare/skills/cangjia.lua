local cangjia = fk.CreateSkill {
  name = "cangjia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cangjia"] = "藏铗",
  [":cangjia"] = "锁定技，当你于出牌阶段外获得牌后，记录此牌花色；你于出牌阶段内不能使用此技能未记录花色的牌。",

  ["@cangjia_record"] = "藏铗",

  ["$cangjia1"] = "满腹韬略，说与谁闻。",
  ["$cangjia2"] = "明珠暗投，乃至于此。",
  ["$cangjia3"] = "唉，空有经纬之才，却无施展之地。",
  ["$cangjia4"] = "非吾才智不足，实乃时运不济。",
}

cangjia:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    return
      player.phase ~= Player.Play and
      player:hasSkill(cangjia.name) and
      table.find(data, function(move)
        return move.to == player and move.toArea == Card.PlayerHand
      end)
  end,
  on_use = function(self, event, target, player, data)
    local suits = player:getTableMark("@cangjia_record")
    table.forEach(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then
        table.forEach(move.moveInfo, function(info)
          table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
        end)
      end
    end)

    player.room:setPlayerMark(player, "@cangjia_record", suits)
  end,
})

cangjia:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return
      player.phase == Player.Play and
      card.suit ~= Card.NoSuit and
      player:hasSkill(cangjia.name) and
      not table.contains(player:getTableMark("@cangjia_record"), card:getSuitString(true))
  end,
})

cangjia:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@cangjia_record", 0)
end)

return cangjia
