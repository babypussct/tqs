local skill = fk.CreateSkill {
  name = "#scaly_wings_skill",
  attached_equip = "scaly_wings",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["#scaly_wings_skill"] = "戢鳞潜翼",
}

skill:addEffect("atkrange", {
  correct_func = function(self, from, to)
    if from:hasSkill(skill.name) then
      return from:getLostHp()
    end
  end,
})

skill:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card and data.card.trueName == "slash" and
    not data.to.dead and data.firstTarget
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return player:inMyAttackRange(p) and data.to ~= p end)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:setPlayerMark(p, skill.name .. "-turn", 1)
      end
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.wings = true
  end,
})

skill:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.wings and data.card.trueName == "slash" and target == player and
    player:hasSkill(skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return p:getMark(skill.name .. "-turn") > 0 end)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, skill.name .. "-turn", 0)
    end
  end,
})

skill:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark(skill.name.."-turn") > 0
  end,
})

return skill
