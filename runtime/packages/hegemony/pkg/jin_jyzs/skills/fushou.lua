local fushou = fk.CreateSkill {
  name = "heg__fushou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["heg__fushou"] = "付授",
  [":heg__fushou"] = "锁定技，与你势力相同的角色无视主副将条件拥有其武将牌上的所有主将技和副将技（计算阴阳鱼的效果除外）。",
}

local H = require "packages.hegemony.util"

local fushou_getspec = {
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    --主将 与 副将技
    for _, p in ipairs(targets) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList()) do
        local skill = Fk.skill_skels[s]
        if table.contains(skill.tags, Skill.DeputyPlace) then
          room:handleAddLoseSkills(p, skill.name, nil, true, false)
        end
      end
    end
    --副将 与 主将技
    for _, p in ipairs(targets) do
      for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList()) do
        local skill = Fk.skill_skels[s]
        if table.contains(skill.tags, Skill.MainPlace) then
          room:handleAddLoseSkills(p, skill.name, nil, true, false)
        end
      end
    end
  end,
}

local fushou_losespec = {
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    for _, p in ipairs(targets) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList()) do
        local skill = Fk.skill_skels[s]
        if table.contains(skill.tags, Skill.DeputyPlace) then
          room:handleAddLoseSkills(p, "-" .. skill.name, nil, true, false)
        end
      end
    end
    for _, p in ipairs(targets) do
      for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList()) do
        local skill = Fk.skill_skels[s]
        if table.contains(skill.tags, Skill.MainPlace) then
          room:handleAddLoseSkills(p, "-" .. skill.name, nil, true, false)
        end
      end
    end
  end,
}

fushou:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(fushou.name)
  end,
  on_refresh = fushou_getspec.on_refresh,
})

fushou:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(fushou.name)
  end,
  on_refresh = fushou_getspec.on_refresh,
})

fushou:addEffect(fk.GeneralHidden, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = fushou_losespec.on_refresh,
})

fushou:addEffect(H.GeneralRemoved, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = fushou_losespec.on_refresh,
})

fushou:addAcquireEffect(function(self, player, is_death)
  local room = player.room
  local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
  for _, p in ipairs(targets) do
    for _, s in ipairs(Fk.generals[p.general]:getSkillNameList()) do
      local skill = Fk.skill_skels[s]
      if table.contains(skill.tags, Skill.DeputyPlace) then
        room:handleAddLoseSkills(p, skill.name, nil, true, false)
      end
    end
  end
  for _, p in ipairs(targets) do
    for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList()) do
      local skill = Fk.skill_skels[s]
      if table.contains(skill.tags, Skill.MainPlace) then
        room:handleAddLoseSkills(p, skill.name, nil, true, false)
      end
    end
  end
end)

fushou:addLoseEffect(function(self, player, is_death)
  local room = player.room
  local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
  for _, p in ipairs(targets) do
    for _, s in ipairs(Fk.generals[p.general]:getSkillNameList()) do
      local skill = Fk.skill_skels[s]
      if table.contains(skill.tags, Skill.DeputyPlace) then
        room:handleAddLoseSkills(p, skill.name, nil, true, false)
      end
    end
  end
  for _, p in ipairs(targets) do
    for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList()) do
      local skill = Fk.skill_skels[s]
      if table.contains(skill.tags, Skill.MainPlace) then
        room:handleAddLoseSkills(p, skill.name, nil, true, false)
      end
    end
  end
end)

fushou:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(fushou.name, true, true) and target == player
  end,
  on_refresh = fushou_losespec.on_refresh,
})

return fushou
