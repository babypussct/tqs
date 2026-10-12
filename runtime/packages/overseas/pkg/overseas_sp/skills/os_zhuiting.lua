local osZhuiting = fk.CreateSkill {
  name = "os__zhuiting",
  tags = { Skill.Lord },
  attached_skill_name = "os__zhuiting_other&",
}

Fk:loadTranslationTable{
  ["os__zhuiting"] = "坠廷",
  [":os__zhuiting"] = "主公技，当一张锦囊牌对你生效前，其他群势力或魏势力角色可以将一张与之颜色相同的手牌当【无懈可击】使用。",
}

osZhuiting:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if (player.kingdom == "qun" or player.kingdom == "wei") and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(osZhuiting.name, true)
    end) then
      room:handleAddLoseSkills(player, osZhuiting.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. osZhuiting.attached_skill_name, nil, false, true)
    end
  end,
})

osZhuiting:addAcquireEffect(function(self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p ~= player then
      local oper = (p.kingdom == "qun" or p.kingdom == "wei") and "" or "-"
      room:handleAddLoseSkills(p, oper .. osZhuiting.attached_skill_name, nil, false, true)
    end
  end
end)

return osZhuiting
