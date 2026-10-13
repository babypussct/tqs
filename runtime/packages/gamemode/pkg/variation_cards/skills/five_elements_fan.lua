local skill = fk.CreateSkill {
  name = "#five_elements_fan_skill",
  attached_equip = "five_elements_fan",
}

Fk:loadTranslationTable{
  ["#five_elements_fan_skill"] = "五行鹤翎扇",
}

skill:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.name ~= "slash" and data.card.trueName == "slash"
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"thunder__slash", "fire__slash", "ice__slash"}
    for _, name in ipairs(Fk:getAllCardNames("b")) do
      local card = Fk:cloneCard(name)
      if name ~= "slash" and card.trueName == "slash" then
        table.insertIfNeed(all_choices, card.name)
      end
    end
    local choices = table.simpleClone(all_choices)
    table.removeOne(choices, data.card.name)
    if #choices > 0 and room:askToSkillInvoke(player, {
      skill_name = skill.name,
    }) then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = skill.name,
        all_choices = all_choices,
      })
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:cloneCard(event:getCostData(self).choice, data.card.suit, data.card.number)
    for k, v in pairs(data.card) do
      if card[k] == nil then
        card[k] = v
      end
    end
    if data.card:isVirtual() then
      card.subcards = data.card.subcards
    else
      card.id = data.card.id
    end
    card.skillNames = data.card.skillNames
    card.skillName = "five_elements_fan"
    data.card = card
  end,
})

return skill
