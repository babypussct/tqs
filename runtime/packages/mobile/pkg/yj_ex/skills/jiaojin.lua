local jiaojin = fk.CreateSkill{
  name = "m_ex__jiaojin",
}

Fk:loadTranslationTable{
  ["m_ex__jiaojin"] = "骄矜",
  [":m_ex__jiaojin"] = "当你受到男性角色造成的伤害时，你可以弃置一张装备牌，防止此伤害。",

  ["#m_ex__jiaojin-discard"] = "骄矜：你可以弃置一张装备牌，防止此伤害",

  ["$m_ex__jiaojin1"] = "狂妄之徒！忘了你自己的身份了吗？",
  ["$m_ex__jiaojin2"] = "和本公主比心机谋算？哼，可笑！",
}

jiaojin:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaojin.name) and data.from and data.from:isMale() and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jiaojin.name,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#m_ex__jiaojin-discard",
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, self.name, player)
    data:preventDamage()
  end,
})

return jiaojin
