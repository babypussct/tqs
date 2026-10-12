local caiqiu = fk.CreateSkill {
  name = "os__caiqiu",
}

Fk:loadTranslationTable{
  ["os__caiqiu"] = "裁裘",
  [":os__caiqiu"] = "每轮开始时，你观看牌堆顶X张牌（X为游戏人数），然后你可以获得其中至少一张牌。若如此做，当其他角色本轮使用牌结算结束后，" ..
  "若此牌与你因此获得的牌存在同名，你失去1点体力（每轮限一次）。",

  ["#os__caiqiu-put"] = "裁裘：你可获得其中至少一张牌，本轮其他角色使用与获得牌同名的牌你失去体力",
  ["@$os__caiqiu_record-round"] = "裁裘",

  ["$os__caiqiu1"] = "衣为礼之大者，岂可草草而决？",
  ["$os__caiqiu2"] = "事关颜面，自是要百里挑一。",
  ["$os__caiqiu3"] = "贱婢好不知耻，竟敢效我衣着。",
  ["$os__caiqiu4"] = "想是夫君宠汝太甚，竟不知尊卑之理。",
}

caiqiu:addEffect(fk.RoundStart, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(caiqiu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local topCards = room:getNCards(#room.players)
    local ret = room:askToArrangeCards(
      player,
      {
        skill_name = caiqiu.name,
        card_map = { topCards, "Top", "toObtain" },
        box_size = 0,
        prompt = "#os__caiqiu-put",
        max_limit = { #topCards, #topCards },
        min_limit = { 0, 0 },
      }
    )

    if #ret[2] > 0 then
      local names = table.map(ret[2], function(id)
        return Fk:getCardById(id).trueName
      end)
      room:obtainCard(player, ret[2], false, fk.ReasonPrey, player, caiqiu.name)
      if player:isAlive() then
        table.forEach(names, function(name)
          room:addTableMarkIfNeed(player, "@$os__caiqiu_record-round", name)
        end)
      end
    end
  end,
})

caiqiu:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:isAlive() and
      table.contains(player:getTableMark("@$os__caiqiu_record-round"), data.card.trueName) and
      player:usedEffectTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, caiqiu.name)
  end,
})

return caiqiu
