
local skill = fk.CreateSkill {
  name = "reveal_intention_skill",
}

skill:addEffect("cardskill", {
  prompt = "#reveal_intention_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    room:addTableMarkIfNeed(player, "reveal_intention-turn", target)
    room:addSkill(skill.name)
    local cards = table.filter(room.discard_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and card.package.name == "nine_variations"
    end)
    if #cards == 0 then return end
    local card = room:askToChooseCard(player, {
      target = player,
      flag = { card_data = {{ skill.name, cards }} },
      skill_name = skill.name,
      prompt = "#reveal_intention-ask::"..target.id,
    })
    if target:canUseTo(Fk:getCardById(card), target) then
      room:useCard{
        from = target,
        tos = { target },
        card = Fk:getCardById(card),
      }
    end
  end,
})

skill:addEffect("atkrange", {
  within_func = function (self, from, to)
    return table.contains(from:getTableMark("reveal_intention-turn"), to)
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.0,
  use_value = 3.5,
  use_priority = 6.0,

  on_effect = function(self, logic, effect)
    local cards = table.filter(Fk:currentRoom().discard_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and card.package.name == "nine_variations"
    end)
    if #cards == 0 then
      logic:damage({
        to = effect.to,
        damage = 1,
      })
    else
    end
  end,
})

return skill
