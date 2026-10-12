local yanzhou = fk.CreateSkill {
  name = "peixiu_yanzhou",
  max_turn_use_time = 1,
}

Fk:loadTranslationTable {
  ["peixiu_yanzhou"] = "兖州",
  [":peixiu_yanzhou"] = "你回复体力后，你摸一张牌（每回合限一次）。",
}

yanzhou:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if not player:hasSkill(self.name) then return false end
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}, { check_skill_limit = true })

return yanzhou
