local skill = fk.CreateSkill {
  name = "looting_skill",
}

Fk:loadTranslationTable{
  ["#looting-give"] = "趁火打劫：点“确定”将此牌交给 %src ，或点“取消”其对你造成1点伤害",
}

skill:addEffect("cardskill", {
  prompt = "#looting_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, _, _, _)
    return to_select ~= player and not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if player.dead or target.dead or target:isKongcheng() then return end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = skill.name,
    })
    target:showCards(id)
    if player.dead or target.dead then return end
    if table.contains(target:getCardIds("h"), id) and
      room:askToSkillInvoke(target, {
        skill_name = skill.name,
        prompt = "#looting-give:"..player.id.."::"..effect.card:toLogString(),
      }) then
      room:obtainCard(player, id, true, fk.ReasonGive, target, skill.name)
    else
      room:damage{
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return skill
