local skill = fk.CreateSkill {
  name = "stab__slash_skill",
}

Fk:loadTranslationTable{
  ["#stab__slash-discard"] = "请弃置一张手牌，否则%arg依然对你生效",
}
local slash_skill = Fk.skills["slash_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = slash_skill.prompt,
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash_skill.canUse,
  mod_target_filter = slash_skill.modTargetFilter,
  target_filter = slash_skill.targetFilter,
  on_effect = slash_skill.onEffect,
})

skill:addEffect(fk.CardEffectCancelledOut, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.card.name == "stab__slash" and data.to == player and not player.dead and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill.name,
      prompt = "#stab__slash-discard:::"..data.card:toLogString(),
      cancelable = true,
    }) == 0 then
      data.isCancellOut = false
    end
  end,
})

return skill
