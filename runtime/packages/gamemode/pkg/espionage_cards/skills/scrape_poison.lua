local skill = fk.CreateSkill {
  name = "scrape_poison_skill",
}

Fk:loadTranslationTable{
  ["#scrape_poison-discard"] = "刮骨疗毒：你可以弃置一张【毒】（不触发失去体力效果）",
}

skill:addEffect("cardskill", {
  prompt = "#scrape_poison_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, _, _, _)
    return to_select:isWounded()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target:isWounded() and not target.dead then
      room:recover({
        who = target,
        num = 1,
        card = effect.card,
        recoverBy = player,
        skillName = skill.name,
      })
    end
    if not target.dead and not target:isKongcheng() then
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = skill.name,
        pattern = "poison",
        prompt = "#scrape_poison-discard",
        cancelable = true,
      })
    end
  end,
})

return skill
