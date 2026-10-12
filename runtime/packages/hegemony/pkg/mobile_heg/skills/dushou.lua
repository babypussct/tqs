
local dushou = fk.CreateSkill{
  name = "m_heg__dushou",
  attached_skill_name = "m_heg__dushou_active&",
}

Fk:loadTranslationTable{
  ["m_heg__dushou"] = "督授",
  [":m_heg__dushou"] = "每名同势力角色的出牌阶段限一次，其可以弃置至多两张牌，令你摸等量的牌。",

  ["$m_heg__dushou1"] = "卿言甚合孤意，此天以卿授我也！",
  ["$m_heg__dushou2"] = "卿若胜则诚快，败则孤自与贼一决！",
  ["$m_heg__dushou3"] = "孤以此剑授卿，有复言者与此案同！",
  ["$m_heg__dushou4"] = "天授东南与孤，今孤当尽付于卿矣！",
}

local H = require "packages.hegemony.util"

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.alive_players
    local src = table.filter(players, function(p)
      return p:hasShownSkill(dushou.name)
    end)
    local dushou_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, chengpu in ipairs(src) do
        if H.compareKingdomWith(chengpu, p) then
          will_attach = true
          break
        end
      end
      dushou_map[p] = will_attach
    end
    for p, v in pairs(dushou_map) do
      if v ~= p:hasSkill("m_heg__dushou_active&") then
        room:handleAddLoseSkills(p, v and dushou.attached_skill_name or "-" .. dushou.attached_skill_name, nil, false, true)
      end
    end
  end,
}

local addLoseEffect = function (self, player, _)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(player, p) then
      room:handleAddLoseSkills(p, dushou.attached_skill_name, nil, false, true)
    end
  end
end
dushou:addAcquireEffect(addLoseEffect)
dushou:addLoseEffect(addLoseEffect)
dushou:addEffect(fk.AfterPropertyChange,spec)
dushou:addEffect(fk.GeneralRevealed, spec)
dushou:addEffect(fk.GeneralHidden, spec)
dushou:addEffect(fk.Deathed, spec)

return dushou
