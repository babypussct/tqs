local osShijun = fk.CreateSkill {
  name = "os__shijun",
  tags = { Skill.Lord },
  attached_skill_name = "os__shijun_other&",
}

Fk:loadTranslationTable{
  ["os__shijun"] = "师君",
  [":os__shijun"] = "主公技，其他群势力角色出牌阶段限一次，若你没有“米”，其可以摸一张牌，然后将一张牌置于你的武将牌上，称为“米”。",
}

osShijun:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player)
    return target == player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(osShijun.name, true)
    end) then
      room:handleAddLoseSkills(player, osShijun.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. osShijun.attached_skill_name, nil, false, true)
    end
  end,
})

osShijun:addAcquireEffect(function(self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p ~= player and p.kingdom == "qun" then
      room:handleAddLoseSkills(p, osShijun.attached_skill_name, nil, false, true)
    end
  end
end)

return osShijun
