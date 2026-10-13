local skill = fk.CreateSkill {
  name = "foresight_skill",
}

skill:addEffect("cardskill", {
  prompt = "#foresight_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    if effect.to.dead then return end
    room:askToGuanxing(effect.to, { cards =room:getNCards(2) })
    room:drawCards(effect.to, 2, skill.name)
  end,
})

return skill
