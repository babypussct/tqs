
local skill = fk.CreateSkill {
  name = "#mobile__wumou__slash_skill",
}

local slash_skill = Fk.skills["slash_skill"] --[[ @as CardSkill ]]

skill:addEffect("cardskill", {
  prompt = "#mobile__wumou__slash_skill",
  max_phase_use_time = 1,
  can_use = function(self, player, card, extra_data)
    if player:prohibitUse(card) then return end
    local c = Fk:getCardById(card.id, true)
    if not (c.multiple_targets and c:getSkill(player).min_target_num == 0) and
      not table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and c:getSkill(player):targetFilter(player, p, {}, {}, c, extra_data)
      end) then
      return false
    end
    return slash_skill:canUse(player, card, extra_data)
  end,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    return to_select ~= player
  end,
  target_filter = function(self, player, to_select, selected, _, card, extra_data)
    if not Util.CardTargetFilter(self, player, to_select, selected, _, card, extra_data) then return end
    local c = Fk:getCardById(card.id, true)
    if c.multiple_targets and c:getSkill(player).min_target_num == 0 then return end
    if not c:getSkill(player):targetFilter(player, to_select, selected, {}, c, extra_data) then return end
    if not Util.CardTargetFilter(self, player, to_select, selected, _, c, extra_data) then return end
    if c.multiple_targets then
      return #selected < c:getSkill(player).max_target_num and
        (player.phase ~= Player.Play or
        (extra_data and extra_data.bypass_times) or
        self:withinTimesLimit(player, Player.HistoryPhase, card, "slash", to_select))
    else
      return slash_skill:targetFilter(player, to_select, selected, _, card, extra_data)
    end
  end,
  fix_targets = function (self, player, selected_cards, card, extra_data)
    local c = Fk:getCardById(card.id, true)
    if c.multiple_targets and c:getSkill(player).min_target_num == 0 then
      local targets = c:getDefaultTarget(player, extra_data)
      table.removeOne(targets, player)
      return targets
    else
      return
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      local c = Fk:getCardById(selected_cards[1], true)
      if c.multiple_targets and c:getSkill(player).min_target_num == 0 then
        return true
      else
        return #selected > 0
      end
    end
  end,
  on_effect = slash_skill.onEffect,
})

return skill
