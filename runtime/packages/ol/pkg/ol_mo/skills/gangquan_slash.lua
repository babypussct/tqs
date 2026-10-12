local slash = fk.CreateSkill{
  name = "gangquan__slash_skill",
}

Fk:loadTranslationTable{
  ["gangquan__slash_skill"] = "火杀",
}

local slash_skill = Fk.skills["fire__slash_skill"] --[[ @as ActiveSkill ]]

slash:addEffect("cardskill", {
  prompt = "#slash_skill",
  max_phase_use_time = 1,
  can_use = function(self, player, card, extra_data)
    if player:prohibitUse(card) then return end
    if (extra_data and extra_data.bypass_times) or player.phase ~= Player.Play then return true end
    local next = player:getNextAlive()
    if next == player then return false end
    if not player:isProhibited(next, card) and self:withinTimesLimit(player, Player.HistoryPhase, card, "slash", next) then
      return true
    end
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:getNextAlive() == player then
        return not player:isProhibited(p, card) and self:withinTimesLimit(player, Player.HistoryPhase, card, "slash", p)
      end
    end
  end,
  mod_target_filter = slash_skill.modTargetFilter,
})

return slash
