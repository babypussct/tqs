local skill = fk.CreateSkill {
  name = "#benshi__slash_skill",
}

local slash_skill = Fk.skills["slash_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = "#benshi_slash_skill",
  max_phase_use_time = 1,
  can_use = slash_skill.canUse,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    return to_select ~= player
  end,
  fix_targets = function (self, player, selected_cards, card, extra_data)
    return table.filter(Fk:currentRoom().alive_players, function (p)
      return player:inMyAttackRange(p)
    end)
  end,
  on_effect = slash_skill.onEffect,
})

return skill
