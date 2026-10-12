local guangling = fk.CreateSkill {
  name = "peixiu_guangling",
}

Fk:loadTranslationTable {
  ["peixiu_guangling"] = "广陵",
  [":peixiu_guangling"] = "你获得此技能后，可以将两张牌当一张【五谷丰登】使用。",

  ["#peixiu_guangling-invoke"] = "广陵：是否将两张牌当【五谷丰登】使用？",
}

guangling:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(guangling.name) and
      data.skill.name == guangling.name and
      (#player:getHandlyIds() + #player:getCardIds("e")) > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "amazing_grace",
      skill_name = guangling.name,
      prompt = "#peixiu_guangling-invoke",
      cancelable = true,
      card_filter = {
        n = 2,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end
})

return guangling
