local nanfu = fk.CreateSkill {
  name = "peixiu_nanfu",
}

Fk:loadTranslationTable {
  ["peixiu_nanfu"] = "南涪",
  [":peixiu_nanfu"] = "你获得此技能后，可以失去1点体力，视为使用一张【杀】。",

  ["#peixiu_nanfu-invoke"] = "南涪：是否失去1点体力，视为使用一张【杀】？",
}

nanfu:addEffect(fk.EventAcquireSkill, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(nanfu.name) and data.skill.name == nanfu.name and
      player.hp > 0 and player:canUse(Fk:cloneCard("slash"), { bypass_times = true })
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = nanfu.name,
      prompt = "#peixiu_nanfu-invoke",
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, nanfu.name)
    room:useCard(event:getCostData(self).extra_data)
  end
})

return nanfu
