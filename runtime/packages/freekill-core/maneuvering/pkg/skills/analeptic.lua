local analepticSkill = fk.CreateSkill {
  name = "analeptic_skill",
}

analepticSkill:addEffect("cardskill", {
  prompt = function(self, _, _, _, extra_data)
    return extra_data.analepticRecover and "#peach_skill" or "#analeptic_skill"
  end,
  max_turn_use_time = 1,
  mod_target_filter = Util.TrueFunc,
  can_use = function(self, player, card, extra_data)
    return Util.CanUseToSelf(self, player, card, extra_data) and
      ((extra_data and (extra_data.bypass_times or extra_data.analepticRecover)) or
      self:withinTimesLimit(player, Player.HistoryTurn, card, "analeptic", player))
  end,
  on_use = function(self, room, use)
    if use.extra_data and use.extra_data.analepticRecover then
      use.extraUse = true
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    if effect.extra_data and effect.extra_data.analepticRecover then
      if to:isWounded() and not to.dead then
        room:recover({
          who = to,
          num = 1,
          recoverBy = effect.from,
          card = effect.card,
          skillName = analepticSkill.name,
        })
      end
    else
      to.drank = to.drank + 1 + ((effect.extra_data or {}).additionalDrank or 0)
      room:broadcastProperty(to, "drank")
    end
  end,
})

analepticSkill:addEffect(fk.PreCardUse, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player.drank > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.additionalDamage = (data.additionalDamage or 0) + player.drank
    data.extra_data = data.extra_data or {}
    data.extra_data.drankBuff = player.drank
    player.drank = 0
    room:broadcastProperty(player, "drank")
  end,
})

analepticSkill:addEffect(fk.TurnEnd, {
  global = true,
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player.drank > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.drank = 0
    player.room:broadcastProperty(player, "drank")
  end,
})

local analepticAI = Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 4.1,
  use_value = 5.98,
  use_priority = 3.0,

  on_effect = function(self, logic, effect)
    if effect.extra_data and effect.extra_data.analepticRecover then
      logic:recover({
        who = effect.to,
        num = 1,
        recoverBy = effect.from,
        card = effect.card,
      })
    elseif logic.ai.command == "PlayCard" then
      -- Drinking is worth the additional damage only when the dashboard has
      -- already confirmed a profitable, legal Slash follow-up.
      logic.benefit = logic.benefit + (logic.ai.mem.analeptic_followup_bonus or 0)
    end
  end
}

local defaultThink = Fk.Ltk.AI.CardSkillStrategy.think

function analepticAI:think(ai)
  if ai.command ~= "PlayCard" then
    return defaultThink(self, ai)
  end

  -- The buff expires at TurnEnd. Probe the same dashboard used by PlayCard so
  -- Slash usage limits, distance, prohibitions and legal targets are respected.
  if (ai.player.drank or 0) > 0 then
    return nil, -100000
  end

  local bestSlashBenefit = 0
  for _, id in ipairs(ai:getEnabledCards()) do
    local card = Fk:getCardById(id)
    if card and card.trueName == "slash" and card.skill then
      ai:selectCard(id, true)
      local slashAI = ai:findStrategyOfSkill(Fk.Ltk.AI.CardSkillStrategy, card.skill.name)
      if slashAI then
        local targets, benefit = slashAI:chooseTargets(ai)
        if targets and #targets > 0 and benefit and benefit > bestSlashBenefit then
          bestSlashBenefit = benefit
        end
      end
      ai:unSelectAll()
    end
  end

  -- Ignore near-zero estimates produced by the generic card-use heuristic.
  -- A genuine attack is worth much more than this threshold.
  if bestSlashBenefit <= 25 then
    return nil, -100000
  end

  ai.mem.analeptic_followup_bonus = bestSlashBenefit + 80
  return defaultThink(self, ai)
end

analepticSkill:addAI(analepticAI)

return analepticSkill
