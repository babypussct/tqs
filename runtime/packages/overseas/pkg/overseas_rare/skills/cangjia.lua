local cangjia = fk.CreateSkill {
  name = "os__cangjia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__cangjia"] = "藏铗",
  [":os__cangjia"] = "锁定技，当你于出牌阶段外获得牌后，记录此牌花色。" ..
    "当你成为其他角色使用的未记录花色的牌的目标后，除非其弃置一张牌，否则此牌对你无效。",

  ["@os__cangjia_record"] = "藏铗",
  ["#os__cangjia-discard"] = "藏铗：你须弃置一张牌，否则 %arg 对 %src 无效",

  ["$os__cangjia1"] = "满腹韬略，说与谁闻。",
  ["$os__cangjia2"] = "明珠暗投，乃至于此。",
  ["$os__cangjia3"] = "唉，空有经纬之才，却无施展之地。",
  ["$os__cangjia4"] = "非吾才智不足，实乃时运不济。",
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
    local suits = player:getTableMark("@os__cangjia_record")
    table.forEach(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then
        table.forEach(move.moveInfo, function(info)
          table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
        end)
      end
    end)

    player.room:setPlayerMark(player, "@os__cangjia_record", suits)
  end,
})

cangjia:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(cangjia.name) or target ~= player then return false end
    local card = data.card
    return
      card.suit ~= Card.NoSuit and
      not table.contains(player:getTableMark("@os__cangjia_record"), card:getSuitString(true))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from.dead or #room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = cangjia.name,
      cancelable = true,
      prompt = "#os__cangjia-discard:"..player.id .. "::" .. data.card:toLogString(),
    }) == 0 then
      data:setNullified(player)
    end
  end,
})

cangjia:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@os__cangjia_record", 0)
end)

return cangjia
