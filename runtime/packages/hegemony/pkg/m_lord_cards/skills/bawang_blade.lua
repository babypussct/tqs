
local skill = fk.CreateSkill {
  name = "#bawang_blade_skill",
  attached_equip = "bawang_blade",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.to ~= player and not data.to.dead and #data.to:getAvailableEquipSlots() > 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      skill_name = skill.name,
      choices = data.to:getAvailableEquipSlots(),
      prompt = "#bawang_blade-abort::"..data.to.id,
    })
    room:abortPlayerArea(data.to, choice)
    if not data.to.dead then
      room:addTableMark(data.to, skill.name, choice)
    end
  end,
})

skill:addEffect(fk.TurnStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark(skill.name) ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(skill.name)
    room:setPlayerMark(player, skill.name, 0)
    for _, slot in ipairs(mark) do
      if not player.dead then
        room:resumePlayerArea(player, slot)
      end
    end
  end,
})

return skill
