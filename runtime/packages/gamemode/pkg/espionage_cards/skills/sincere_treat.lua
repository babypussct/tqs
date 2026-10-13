local skill = fk.CreateSkill {
  name = "sincere_treat_skill",
}

Fk:loadTranslationTable{
  ["#sincere_treat-give"] = "推心置腹：请交给 %dest %arg张手牌",
}

local snatch_skill = Fk.skills["snatch_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = "#sincere_treat_skill",
  distance_limit = 1,
  target_num = 1,
  mod_target_filter = snatch_skill.modTargetFilter,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if player.dead or target.dead or target:isAllNude() then return end
    local cards = room:askToChooseCards(player, {
      target = target,
      min = 1,
      max = 2,
      flag = "hej",
      skill_name = skill.name,
    })
    room:obtainCard(player, cards, false, fk.ReasonPrey, player, skill.name)
    if not player.dead and not target.dead or player:isKongcheng() then
      local n = math.min(#cards, player:getHandcardNum())
      cards = room:askToCards(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = skill.name,
        prompt = "#sincere_treat-give::"..target.id..":"..n,
        cancelable = false,
      })
      room:obtainCard(target, cards, false, fk.ReasonGive, player, skill.name)
    end
  end,
})

return skill
