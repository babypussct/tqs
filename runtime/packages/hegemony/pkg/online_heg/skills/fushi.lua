local fushi = fk.CreateSkill {
  name = "ol_heg__fushi",
  tags = { Skill.Compulsory },
  related_skills = { "ol_heg__zezhu", "ol_heg__chenggong" },
}

Fk:loadTranslationTable {
  ["ol_heg__fushi"] = "附势",
  [":ol_heg__fushi"] = "锁定技，若你的上家为群势力角色，你视为拥有〖择主〗；若你的下家为魏势力角色，你视为拥有〖逞功〗。",

  ["@@ol_heg__fushi-zezhu"] = "择主",
  ["@@ol_heg__fushi-chenggong"] = "逞功",
}

local H = require "packages.hegemony.util"

local fushi_spec = {
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(fushi.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local prev = player:getLastAlive()
    local next = player:getNextAlive()
    if player:hasSkill(fushi.name) then
      local qun = H.getKingdom(prev) == "qun"
      local wei = H.getKingdom(next) == "wei"
      room:handleAddLoseSkills(player, qun and "ol_heg__zezhu" or "-ol_heg__zezhu", nil, false, true)
      room:setPlayerMark(player, "@@ol_heg__fushi-zezhu", qun and 1 or 0)
      room:handleAddLoseSkills(player, wei and "ol_heg__chenggong" or "-ol_heg__chenggong", nil, false, true)
      room:setPlayerMark(player, "@@ol_heg__fushi-chenggong", wei and 1 or 0)
    end
  end,
}

fushi:addEffect(fk.TurnStart, fushi_spec)
fushi:addEffect(fk.GeneralRevealed, fushi_spec)
fushi:addEffect(fk.EventAcquireSkill, fushi_spec)
fushi:addEffect(H.PlayerRemoved, fushi_spec)
fushi:addEffect(fk.Deathed, fushi_spec)
fushi:addEffect(fk.GeneralHidden, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = fushi_spec.on_refresh,
})

fushi:addLoseEffect(function(self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p:hasSkill("ol_heg__zezhu") then
      room:handleAddLoseSkills(p, "-ol_heg__zezhu", nil, false, true)
      if p:getMark("@@ol_heg__fushi-zezhu") > 0 then room:setPlayerMark(p, "@@ol_heg__fushi-zezhu", 0) end
    end
    if p:hasSkill("ol_heg__chenggong") then
      room:handleAddLoseSkills(p, "-ol_heg__chenggong", nil, false, true)
      if p:getMark("@@ol_heg__fushi-chenggong") > 0 then room:setPlayerMark(player, "@@ol_heg__fushi-chenggong", 0) end
    end
  end
end)

return fushi
