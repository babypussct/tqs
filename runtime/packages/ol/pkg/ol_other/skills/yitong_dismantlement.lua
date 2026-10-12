local skill = fk.CreateSkill {
  name = "#yitong__dismantlement_skill",
}

local dismantlement_skill = Fk.skills["dismantlement_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = "#yitong_dismantlement_skill",
  can_use = Util.CanUseFixedTarget,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    return to_select ~= player and not to_select:isAllNude()
  end,
  fix_targets = function (self, player, selected_cards, card, extra_data)
    return table.filter(Fk:currentRoom().alive_players, function (p)
      return p.kingdom ~= "qin"
    end)
  end,
  on_effect = dismantlement_skill.onEffect,
})

return skill
