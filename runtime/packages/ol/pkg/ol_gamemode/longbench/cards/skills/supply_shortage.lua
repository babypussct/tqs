local skill = fk.CreateSkill {
  name = "v11_lb__supply_shortage_skill",
}

Fk:loadTranslationTable{
  ["@@v11_lb__supply_shortage-turn"] = "兵粮寸断",
}

skill:addEffect("cardskill", {
  prompt = "#v11_lb__supply_shortage_skill",
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = effect.to
    local judge = {
      who = to,
      reason = "v11_lb__supply_shortage",
      pattern = ".|.|^club",
    }
    room:judge(judge)
    if judge:matchPattern() then
      room:addPlayerMark(to, "@@v11_lb__supply_shortage-turn")
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
  global = true,
  can_refresh = function (self, event, target, player, data)
    return player == target and player:getMark("@@v11_lb__supply_shortage-turn") > 0
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
    return player == target and player:getMark("@@v11_lb__supply_shortage-turn") > 0 and player.phase == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        p:drawCards(1, skill.name)
      end
    end
  end,
})

return skill
