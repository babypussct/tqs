local osChongqi = fk.CreateSkill {
  name = "os__chongqi",
  tags = { Skill.Compulsory },
  related_skills = { "os__feifu" },
}

Fk:loadTranslationTable{
  ["os__chongqi"] = "宠齐",
  [":os__chongqi"] = "锁定技，所有角色视为拥有技能〖非服〗；游戏开始时，你可以减1点体力上限，令一名其他角色获得〖复纂〗。",

  ["#os__chongqi-ask"] = "宠齐：你可减1点体力上限，令一名其他角色获得〖复纂〗",

  ["$os__chongqi1"] = "吾既身承宠遇，敢不为君分忧？",
  ["$os__chongqi2"] = "臣得君上垂青，已是此生之幸。",
}

osChongqi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osChongqi.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:handleAddLoseSkills(p, "os__feifu", nil, false, true)
    end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return (not p:hasSkill("os__fuzuan"))
    end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__chongqi-ask",
        skill_name = osChongqi.name,
      }
    )
    if #tos > 0 then
      room:changeMaxHp(player, -1)
      room:handleAddLoseSkills(tos[1], "os__fuzuan")
    end
  end,
})

osChongqi:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:handleAddLoseSkills(p, "os__feifu", nil, false, true)
    end
  end
end)

return osChongqi
