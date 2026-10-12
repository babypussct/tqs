local liangzhou = fk.CreateSkill {
  name = "peixiu_liangzhou2",
}

Fk:loadTranslationTable {
  ["peixiu_liangzhou2"] = "凉州",
  [":peixiu_liangzhou2"] = "你获得此技能后，可以将一张黑色牌当【杀】使用。",

  ["#peixiu_liangzhou2-invoke"] = "凉州：你可以将一张黑色牌当【杀】使用",
}

liangzhou:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(liangzhou.name) and data.skill.name == liangzhou.name
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = liangzhou.name,
      prompt = "#peixiu_liangzhou2-invoke",
      cancelable = true,
      card_filter = {
        n = 1,
        pattern = ".|.|black",
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

return liangzhou
