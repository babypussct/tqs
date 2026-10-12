local xiyan = fk.CreateSkill {
  name = "os__xiyan",
}

Fk:loadTranslationTable{
  ["os__xiyan"] = "夕颜",
  [":os__xiyan"] = "每次增加“怨”时，若“怨”的花色数达到4种，你可以获得所有“怨”。然后若此时是你的回合，你的〖怨语〗视为未发动过，"..
  "本回合手牌上限+4且使用牌无次数限制；若不是你的回合，你可以令当前回合角色本回合手牌上限-4且本回合不能使用基本牌。",

  ["#os__xiyan-debuff"] = "夕颜：是否令 %dest 本回合不能使用基本牌且手牌上限-4",
  ["@@os__xiyan_prohibit-turn"] = "夕颜 不能出牌",

  ["$os__xiyan1"] = "及君偕老，老使我怨，弱水相阻，此生不见。",
  ["$os__xiyan2"] = "卿无渡河，卿竟渡河，河公溺我，当奈卿何。",
}

xiyan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiyan.name) then
      local suits = {}
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerSpecial and move.specialName == "@[os__yuanyu_resent]" then
          for _, id in ipairs(player:getPile("@[os__yuanyu_resent]")) do
            table.insertIfNeed(suits, Fk:getCardById(id).suit)
          end
          table.removeOne(suits, Card.NoSuit)
        end
      end
      return #suits > 3
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(player:getTableMark("os__yuanyu_targets")) do
      room:removePlayerMark(room:getPlayerById(pid), "@@os__yuanyu")
    end
    room:setPlayerMark(player, "os__yuanyu_targets", 0)
    room:moveCardTo(player:getPile("@[os__yuanyu_resent]"), Card.PlayerHand, player, fk.ReasonJustMove, xiyan.name, nil, true, player)
    if room.current and not room.current.dead and room.current.phase ~= Player.NotActive then
      if room.current == player then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 4)
        player:setSkillUseHistory("#os__yuanyu_main_skill")
        room:addPlayerMark(player, "os__xiyan_targetmod-turn")
      elseif room:askToSkillInvoke(player, {
          skill_name = xiyan.name,
          prompt = "#os__xiyan-debuff::" .. room.current.id,
        }) then
        room:addPlayerMark(room.current, MarkEnum.MinusMaxCardsInTurn, 4)
        room:addPlayerMark(room.current, "@@os__xiyan_prohibit-turn")
      end
    end
  end,
})

xiyan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("os__xiyan_targetmod-turn") > 0
  end,
})

xiyan:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@os__xiyan_prohibit-turn") > 0 and card and card.type == Card.TypeBasic
  end,
})

return xiyan