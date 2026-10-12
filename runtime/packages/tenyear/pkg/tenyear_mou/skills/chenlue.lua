local chenlue = fk.CreateSkill {
  name = "chenlue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["chenlue"] = "沉略",
  [":chenlue"] = "限定技，出牌阶段，你可以从牌堆、弃牌堆、场上或其他角色的手牌中获得所有“死士”牌，此阶段结束时，将这些牌移出游戏直到你死亡。",

  ["#chenlue"] = "沉略：获得所有“死士”，此阶段结束时移出游戏！",
  ["#chenlue_pile"] = "沉略",

  ["$chenlue1"] = "怀泰山之重，必立以千仞。",
  ["$chenlue2"] = "万世之勋待取，此乃亮剑之时。",
}

chenlue:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#chenlue",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(chenlue.name, Player.HistoryGame) == 0 and player:getMark("sanshi") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local areas = { Card.PlayerEquip, Card.PlayerJudge, Card.DrawPile, Card.DiscardPile }
    local handcards = player:getCardIds("h")
    local cards = table.filter(player:getTableMark("sanshi"), function(id)
      local area = room:getCardArea(id)
      return table.contains(areas, area) or (area == Card.PlayerHand and not table.contains(handcards, id))
    end)
    if #cards > 0 then
      room:setPlayerMark(player, "chenlue-phase", cards)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, chenlue.name, nil, true, player)
    end
  end,
})

chenlue:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  audio_index = 0,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenlue.name) and player:getMark("chenlue-phase") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local areas = { Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge, Card.DrawPile, Card.DiscardPile }
    local cards = table.filter(player:getTableMark("chenlue-phase"), function(id)
      local area = room:getCardArea(id)
      return table.contains(areas, area)
    end)
    if #cards > 0 then
      room:setPlayerMark(player, chenlue.name, cards)
      room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, chenlue.name, nil, true, player)
    end
  end,
})

chenlue:addEffect(fk.Death, {
  anim_type = "negative",
  is_delay_effect = true,
  audio_index = 0,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(chenlue.name, false, true) and player:getMark(chenlue.name) ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getTableMark(chenlue.name), function(id)
      return room:getCardArea(id) == Card.Void
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, chenlue.name, nil, true, player)
    end
  end,
})

chenlue:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "chenlue-phase", 0)
  room:setPlayerMark(player, chenlue.name, 0)
end)

return chenlue
