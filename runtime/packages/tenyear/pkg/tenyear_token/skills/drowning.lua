local skill = fk.CreateSkill {
  name = "ty__drowning_skill",
}

Fk:loadTranslationTable{
  ["ty__drowning_skill"] = "水淹七军",
  ["#ty__drowning_skill"] = "选择1-2名目标角色，第一名角色受到1点雷电伤害并弃牌，第二名角色受到1点雷电伤害并摸牌",
}

skill:addEffect("cardskill", {
  prompt = "#ty__drowning_skill",
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = Util.TrueFunc,
  target_filter = Util.CardTargetFilter,
  on_use = function(self, room, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.ty__drowning_targets = table.simpleClone(use.tos)
  end,
  on_action = function(self, room, use)
    if type((use.extra_data or {}).ty__drowning_targets) == "table" then
      for _, p in ipairs(use.extra_data.ty__drowning_targets) do
        if table.removeOne(use.tos, p) then
          table.insert(use.tos, p)
        end
      end
    end
  end,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    room:damage{
      from = from,
      to = to,
      card = effect.card,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = skill.name
    }
    if not to.dead then
      if effect.use.tos[1] == effect.to then
        room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skill.name,
          cancelable = false,
        })
      else
        to:drawCards(1, skill.name)
      end
    end
  end,
})

return skill
