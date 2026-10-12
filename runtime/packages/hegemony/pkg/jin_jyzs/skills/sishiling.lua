local skill = fk.CreateSkill{
    name = "#sishiling",
}

Fk:loadTranslationTable{
    ["#sishiling"] = "死士令",
}

local H = require "packages.hegemony.util"

local skill_attach = function (player)
    local room = player.room
    local players = room.alive_players
    local lordsunquans = table.filter(players, function(p) return p:hasShownSkill(skill.name) end)
    local jiahe_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, ld in ipairs(lordsunquans) do
        if H.compareKingdomWith(ld, p) then
          will_attach = true
          break
        end
      end
      jiahe_map[p] = will_attach
    end
    for p, v in pairs(jiahe_map) do
      if v ~= p:hasSkill("sishiling_other&") then
        room:handleAddLoseSkills(p, v and "sishiling_other&" or "-sishiling_other&", nil, false, true)
      end
    end
  end

skill:addAcquireEffect(function (self, player, is_start)
  skill_attach(player)
end)
skill:addLoseEffect(function (self, player, is_death)
  skill_attach(player)
end)

skill:addEffect(fk.Deathed,{
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(skill.name, true, true) and target == player
  end,
  on_refresh = function (self, event, target, player, data)
    skill_attach(player)
  end,
})

skill:addEffect(fk.GeneralRevealed,{
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    skill_attach(player)
  end,
})

return skill