local skill = fk.CreateSkill {
  name = "#yitong__fire_attack_skill",
}

local fire_attack_skill = Fk.skills["fire_attack_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = "#yitong_fire_attack_skill",
  can_use = Util.CanUseFixedTarget,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    return not to_select:isKongcheng()
  end,
  fix_targets = function (self, player, selected_cards, card, extra_data)
    return table.filter(Fk:currentRoom().alive_players, function (p)
      return p.kingdom ~= "qin"
    end)
  end,
  on_effect = fire_attack_skill.onEffect,
})

return skill
