
local duorui = fk.CreateSkill {
  name = "ty__duorui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__duorui"] = "夺锐",
  [":ty__duorui"] = "锁定技，你对其他角色造成伤害时，你废除其一个装备栏直到你的下个出牌阶段开始。",

  ["#ty__duorui-abort"] = "夺锐：废除 %dest 一个装备栏",

  ["$ty__duorui1"] = "力慑孙仲谋，威震逍遥津！",
  ["$ty__duorui2"] = "我有八百壮士，可斩将、刈旗、夺锐！",
}

duorui:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duorui.name) and
      data.to ~= player and not data.to.dead and #data.to:getAvailableEquipSlots() > 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      skill_name = duorui.name,
      choices = data.to:getAvailableEquipSlots(),
      prompt = "#ty__duorui-abort::"..data.to.id,
    })
    room:abortPlayerArea(data.to, choice)
    if not player.dead and not data.to.dead then
      room:addTableMark(player, duorui.name, { data.to, choice })
    end
  end,
})

duorui:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:getMark(duorui.name) ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(duorui.name)
    room:setPlayerMark(player, duorui.name, 0)
    for _, dat in ipairs(mark) do
      if not dat[1].dead then
        room:resumePlayerArea(dat[1], dat[2])
      end
    end
  end,
})

return duorui
