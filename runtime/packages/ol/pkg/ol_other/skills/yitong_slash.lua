local skill = fk.CreateSkill {
  name = "#yitong__slash_skill",
}

local slash_skill = Fk.skills["slash_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = "#yitong_slash_skill",
  max_phase_use_time = 1,
  can_use = function(self, player, card, extra_data)
    if player:prohibitUse(card) then return end
    return (extra_data and extra_data.bypass_times) or player.phase ~= Player.Play or
      self:withinTimesLimit(player, Player.HistoryPhase, card, "slash") or
      table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p.kingdom ~= "qin" and self:withinTimesLimit(player, Player.HistoryPhase, card, "slash", p)
      end) ~= nil
  end,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    return to_select ~= player
  end,
  fix_targets = function (self, player, selected_cards, card, extra_data)
    return table.filter(Fk:currentRoom().alive_players, function (p)
      return p ~= player and p.kingdom ~= "qin"
    end)
  end,
  on_effect = slash_skill.onEffect,
})

return skill
