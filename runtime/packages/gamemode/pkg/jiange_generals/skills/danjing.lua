local danjing = fk.CreateSkill{
  name = "jiange__danjing",
}

Fk:loadTranslationTable{
  ["jiange__danjing"] = "啖睛",
  [":jiange__danjing"] = "其他友方角色处于濒死状态时，若你的体力值大于1，你可以失去1点体力，视为你对其使用一张【桃】。",

  ["#jiange__danjing-invoke"] = "啖睛：是否失去1点体力，视为对 %dest 使用【桃】？",
}

danjing:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(danjing.name) and target ~= player and target:isFriend(player) and
      player.hp > 1 and target.dying
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = danjing.name,
      prompt = "#jiange__danjing-invoke::"..target.id
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, danjing.name)
    if not target.dead then
      room:useVirtualCard("peach", nil, player, target, danjing.name)
    end
  end,
})

return danjing
