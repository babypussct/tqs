local skill = fk.CreateSkill {
  name = "bogus_flower_skill",
}

Fk:loadTranslationTable{
  ["#bogus_flower-discard"] = "树上开花：弃置一至两张牌，摸等量的牌，若弃置了装备牌则多摸一张",
}

skill:addEffect("cardskill", {
  prompt = "#bogus_flower_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    local target = effect.to
    if target.dead or target:isNude() then return end
    local cards = room:askToDiscard(target, {
      min_num = 1,
      max_num = 2,
      include_equip = true,
      skill_name = skill.name,
      prompt = "#bogus_flower-discard",
      cancelable = true,
      skip = true,
    })
    if #cards == 0 then return end
    local n = #cards
    if table.find(cards, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end) then
      n = n + 1
    end
    room:throwCard(cards, skill.name, target, target)
    if not target.dead then
      target:drawCards(n, skill.name)
    end
  end,
})

return skill
