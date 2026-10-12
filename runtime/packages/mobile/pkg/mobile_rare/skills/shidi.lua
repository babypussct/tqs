local shidi = fk.CreateSkill {
  name = "shidi",
  tags = { Skill.Compulsory, Skill.Switch },
}

Fk:loadTranslationTable{
  ["shidi"] = "势敌",
  [":shidi"] = "锁定技，转换技，准备阶段转换为阳，结束阶段转换为阴；"..
  "阳：你计算与其他角色的距离-1，且你使用的黑色【杀】不可被响应；"..
  "阴：其他角色计算与你的距离+1，且你不可响应其他角色对你使用的红色【杀】。",

  ["$shidi1"] = "诈败以射之，其必死矣！",
  ["$shidi2"] = "呃啊，中其拖刀计矣！",
}

shidi:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shidi.name) then
      if player:getSwitchSkillState(shidi.name) == fk.SwitchYin then
        return player.phase == Player.Start
      elseif player:getSwitchSkillState(shidi.name) == fk.SwitchYang then
        return player.phase == Player.Finish
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(shidi.name, player:getSwitchSkillState(shidi.name) + 1)
    player.room:notifySkillInvoked(player, shidi.name, "switch")
  end,
})
shidi:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shidi.name) and data.card.trueName == "slash" then
      if player:getSwitchSkillState(shidi.name) == fk.SwitchYang then
        return data.card.color == Card.Black and target == player
      elseif player:getSwitchSkillState(shidi.name) == fk.SwitchYin then
        return data.card.color == Card.Red and target ~= player and table.contains(data.tos, player)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    if player:getSwitchSkillState(shidi.name) == fk.SwitchYang then
      data.disresponsiveList = table.simpleClone(player.room.players)
    else
      table.insertIfNeed(data.disresponsiveList, player)
    end
  end,
})
shidi:addEffect("distance", {
  correct_func = function(self, from, to)
    local n = 0
    if from:hasSkill(shidi.name) and from:getSwitchSkillState(shidi.name) == fk.SwitchYang then
      n = n - 1
    end
    if to:hasSkill(shidi.name) and to:getSwitchSkillState(shidi.name) == fk.SwitchYin then
      n = n + 1
    end
    return n
  end,
})

return shidi
