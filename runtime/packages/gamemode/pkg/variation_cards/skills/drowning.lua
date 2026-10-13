local skill = fk.CreateSkill {
  name = "drowning_skill",
}

Fk:loadTranslationTable{
  ["#drowning-discard"] = "水淹七军：点“确定”弃置装备区所有牌，或点“取消”%dest 对你造成1点雷电伤害",
}

skill:addEffect("cardskill", {
  prompt = "#drowning_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and #to_select:getCardIds("e") > 0
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if #to:getCardIds("e") == 0 or
      not room:askToSkillInvoke(to, {
      skill_name = skill.name,
      prompt = "#drowning-discard::"..from.id,
      }) then
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = skill.name,
      })
    else
      to:throwAllCards("e")
    end
  end,
})

return skill
