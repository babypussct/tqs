local skill = fk.CreateSkill {
  name = "#golden_coronet_skill",
  attached_equip = "golden_coronet",
}

Fk:loadTranslationTable{
  ["#golden_coronet_skill"] = "束发紫金冠",
  ["#golden_coronet-choose"] = "束发紫金冠：你可以对一名其他角色造成1点伤害",
}

skill:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = skill.name,
      prompt = "#golden_coronet-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:damage {
      from = player,
      to = to,
      damage = 1,
      skillName = skill.name,
    }
  end,
})

return skill
