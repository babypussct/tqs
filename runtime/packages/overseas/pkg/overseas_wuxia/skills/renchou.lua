local renchou = fk.CreateSkill {
  name = "os__renchou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__renchou"] = "刃仇",
  [":os__renchou"] = "锁定技，当你死亡时，你令〖言誓〗选择的角色获得〖言誓〗。" ..
    "当〖言誓〗选择的角色死亡后，本局游戏有“誓”的角色不能响应你使用的牌。",

  ["@@os__renchou"] = "刃仇",

  ["$os__renchou1"] = "塞亡父之冤魂，血三弟之永恨！",
  ["$os__renchou2"] = "禄福夜雪白，都亭朝霞红！"
}

renchou:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(renchou.name, false, true) then
      local to = player:getMark("@os__yanshi")
      if to ~= 0 and to:isAlive() and not to:hasSkill("os__yanshi") then
        event:setCostData(self, { tos = { to } })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:handleAddLoseSkills(to, { "os__yanshi" })
  end,
})

renchou:addEffect(fk.Deathed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(renchou.name) and target ~= player and
      target == player:getMark("@os__yanshi")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__yanshi", 0)
    room:setPlayerMark(player, "@@os__renchou", 1)
  end,
})

renchou:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(renchou.name) and player:getMark("@@os__renchou") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.filter(player.room.players, function(p)
      return p:getMark("@os__oath") ~= 0
    end)
  end,
})

return renchou
