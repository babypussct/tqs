local skill = fk.CreateSkill {
  name = "v33__ex_nihilo_skill",
}

skill:addEffect("cardskill", {
  prompt = function (self, player, selected_cards, selected_targets, extra_data)
    local n = 2
    if #player:getFriends() < #player:getEnemies() then
      n = 3
    end
    return "#v33__ex_nihilo_skill:::"..n
  end,
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    local target = effect.to
    if target.dead then return end
    if #target:getFriends() < #target:getEnemies() then
      target:drawCards(3, skill.name)
    else
      target:drawCards(2, skill.name)
    end
  end,
})

return skill
