local osJuxiang = fk.CreateSkill {
  name = "os__juxiang",
  tags = { Skill.Lord },
  attached_skill_name = "os__juxiang_other&",
}

Fk:loadTranslationTable{
  ["os__juxiang"] = "踞襄",
  [":os__juxiang"] = "主公技，其他群势力角色出牌阶段限一次，其可以选择其装备区的一张牌置于你的装备区中，" ..
  "若你对应的装备栏已被废除，则改为交给你此装备牌，然后恢复你的对应装备栏。",
}

osJuxiang:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player)
    return target == player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(osJuxiang.name, true)
    end) then
      room:handleAddLoseSkills(player, osJuxiang.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. osJuxiang.attached_skill_name, nil, false, true)
    end
  end,
})

osJuxiang:addAcquireEffect(function(self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p ~= player and p.kingdom == "qun" then
      room:handleAddLoseSkills(p, osJuxiang.name, nil, false, true)
    end
  end
end)

return osJuxiang
