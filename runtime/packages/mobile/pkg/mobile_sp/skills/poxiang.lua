local poxiang = fk.CreateSkill {
  name = "poxiang",
}

Fk:loadTranslationTable{
  ["poxiang"] = "破降",
  [":poxiang"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，然后你摸三张牌，移去所有“绝”并失去1点体力，你以此法获得的牌本回合不计入手牌上限。",

  ["#poxiang-active"] = "发动破降，选择一张牌交给一名角色，然后摸三张牌，移去所有绝并失去1点体力",
  ["@@poxiang-inhand-turn"] = "破降",

  ["$poxiang1"] = "王瓘既然假降，吾等可将计就计。",
  ["$poxiang2"] = "佥率已降两千魏兵，便可大破魏军主力。",
}

poxiang:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#poxiang-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(poxiang.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player and #cards > 0
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = poxiang.name
    local player = effect.from
    room:moveCardTo(effect.cards, Card.PlayerHand, effect.tos[1], fk.ReasonGive, skillName, "", false, player)
    if not player:isAlive() then return end
    player:drawCards(3, skillName, nil, "@@poxiang-inhand-turn")
    local pile = player:getPile("jueyong_desperation")
    if #pile > 0 then
      room:moveCards({
        from = player,
        ids = pile,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = skillName,
      })
    end
    if not player:isAlive() then return end
    room:loseHp(player, 1, skillName)
  end,
})

poxiang:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@poxiang-inhand-turn") > 0
  end,
})

return poxiang
