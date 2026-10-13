local skill = fk.CreateSkill {
  name = "wenhe_chaos_skill",
}

skill:addEffect("cardskill", {
  prompt = "#wenhe_chaos_skill",
  can_use = Util.AoeCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, false)
  end,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player
  end,
  on_effect = function(self, room, effect)
    local target = effect.to
    local other_players = table.filter(room:getOtherPlayers(target, false), function(p)
      return not p:isRemoved()
    end)
    local luanwu_targets = table.filter(other_players, function(p2)
      return table.every(other_players, function(p1)
        return target:distanceTo(p1) >= target:distanceTo(p2)
      end)
    end)
    local use = room:askToUseCard(target, {
      pattern = "slash",
      prompt = "#luanwu-use",
      cancelable = true,
      extra_data = {
        exclusive_targets = table.map(luanwu_targets, Util.IdMapper),
        bypass_times = true,
      },
      skill_name = skill.name,
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      room:loseHp(target, 1, skill.name)
    end
  end,
})

return skill
