local skill = fk.CreateSkill {
  name = "armed_and_fed_skill",
}

local function addGrain(room, player, num)
  room:addPlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_gain",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

skill:addEffect("cardskill", {
  prompt = "#armed_and_fed_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    if effect.to.dead then return end
    addGrain(room, effect.to, 5)
  end,
})

return skill
