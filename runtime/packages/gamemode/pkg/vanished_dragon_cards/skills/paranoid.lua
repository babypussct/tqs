local skill = fk.CreateSkill {
  name = "paranoid_skill",
}

Fk:loadTranslationTable{
  ["@@paranoid-turn"] = "草木皆兵",
}

skill:addEffect("cardskill", {
  prompt = "#paranoid_skill",
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = effect.to
    local judge = {
      who = to,
      reason = "paranoid",
      pattern = ".|.|^club",
    }
    room:judge(judge)
    if judge:matchPattern() then
      room:addPlayerMark(to, "@@paranoid-turn")
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse,
    }
  end,
})

skill:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return player == target and player:getMark("@@paranoid-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n - 1
  end,
})

skill:addEffect(fk.EventPhaseEnd, {
  global = true,
  priority = 0.1,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@paranoid-turn") > 0 and player.phase == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:distanceTo(target) == 1
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(1, skill.name)
      end
    end
  end,
})

skill:addAI(nil, "__card_skill")

return skill
