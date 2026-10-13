local skill = fk.CreateSkill {
  name = "reinforcement_skill",
}

Fk:loadTranslationTable{
  ["reinforcement_nonbasic"] = "弃置一张非基本牌",
  ["reinforcement_2cards"] = "弃置两张牌",
}

skill:addEffect("cardskill", {
  prompt = "#reinforcement_skill",
  target_num = 1,
  mod_target_filter = Util.TrueFunc,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    if to.dead then return end
    to:drawCards(3, skill.name)
    if to.dead then return end
    local all_choices = { "reinforcement_nonbasic", "reinforcement_2cards" }
    local choices = table.clone(all_choices)
    if #table.filter(to:getCardIds("he"), function (id)
      return not to:prohibitDiscard(id)
    end) < 2 then
      table.remove(choices, 2)
    end
    if not table.find(to:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic and not to:prohibitDiscard(id)
    end) then
      table.remove(choices, 1)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = skill.name,
      all_choices = all_choices,
    })
    if choice == "reinforcement_nonbasic" then
      room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skill.name,
        pattern = ".|.|.|.|.|^basic",
        cancelable = false,
      })
    else
      room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = skill.name,
        cancelable = false,
      })
    end
  end,
})

return skill
