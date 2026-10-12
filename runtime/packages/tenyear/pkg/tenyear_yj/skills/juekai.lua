local juekai = fk.CreateSkill {
  name = "juekai",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["juekai"] = "绝忾",
  [":juekai"] = "限定技，出牌阶段，你可以重置〖忠锷〗，然后直到出牌阶段结束，此阶段获得过牌的角色无法再使用手牌。",

  ["#juekai"] = "绝忾：重置〖忠锷〗，然后直到出牌阶段结束，此阶段获得过牌的角色无法再使用手牌",
  ["juekai_target"] = "获得过牌",
  ["@@juekai_prohibit-phase"] = "绝忾",

  ["$juekai1"] = "吾当与贼同死此刀下！",
  ["$juekai2"] = "吾誓不与贼同立于皇天后土！",
}

juekai:addEffect("active", {
  anim_type = "control",
  prompt = "#juekai",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if to_select:getMark("juekai-phase") > 0 then
      return { {content = "juekai_target", type = "normal"} }
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(juekai.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:hasSkill("zhonge", true) then
      player:clearSkillHistory("zhonge")
    end
    room:setBanner("juekai-phase", true)
  end,
})

juekai:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("juekai-phase") == 0 or Fk:currentRoom():getBanner("juekai-phase") == nil then return false end
    local subcards = card:isVirtual() and card.subcards or { card.id }
    return #subcards > 0 and
      table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
  end,
})

juekai:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:getMark("juekai-phase") ~= 0 or player.dead then return false end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "juekai-phase", 1)
  end,
})

juekai:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      for _, move in ipairs(e.data) do
        if move.to and not move.to.dead and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
          room:setPlayerMark(move.to, "juekai-phase", 1)
        end
      end
    end, Player.HistoryPhase)
  end
end)

return juekai
