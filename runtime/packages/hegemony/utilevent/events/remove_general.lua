---@class HegUtil
local HegUtil = require "packages.hegemony.utilevent._base"

---@class HegUtil.GameEvent.RemoveGeneral : GameEvent
---@field public data HegUtil.GeneralRemoveData
local RemoveGeneral = GameEvent:subclass("HegUtil.GameEvent.RemoveGeneral")

function RemoveGeneral:__tostring()
  local data = self.data
  local position = data.isDeputy and "deputyGeneral" or "mainGeneral"
  return string.format("<RemoveGeneral %s : %s[%s] #%d>",
    position, data.who, data.skillName, self.id)
end

function RemoveGeneral:main()
  local rgdata = self.data
  local room = self.room
  local logic = room.logic
  local player, isDeputy = rgdata.who, rgdata.isDeputy
  player:setMark("CompanionEffect", 0)
  player:setMark("HalfMaxHpLeft", 0)
  player:doNotify("SetPlayerMark", { player.id, "CompanionEffect", 0})
  player:doNotify("SetPlayerMark", { player.id, "HalfMaxHpLeft", 0})

  --if player.kingdom == "unknown" then player:revealGeneral(isDeputy, true) end 
  player:revealGeneral(isDeputy, true) -- FIXME: 先摆

  local orig = isDeputy and (player.deputyGeneral or "") or player.general
  rgdata.origName = orig
  if orig:startsWith("blank_") then return false end

  if logic:trigger(HegUtil.GeneralRemoving, player, rgdata) then
    logic:breakEvent(false)
  end

  orig = isDeputy and (player.deputyGeneral or "") or player.general
  if orig:startsWith("blank_") then return false end
  local orig_general = Fk.generals[orig]

  local orig_skills = orig_general and orig_general:getSkillNameList() or {}

  local new_general = orig_general.gender == General.Male and "blank_shibing" or "blank_nvshibing"

  orig_skills = table.map(orig_skills, function(e)
    return "-" .. e
  end)

  room:handleAddLoseSkills(player, table.concat(orig_skills, "|"), nil, false)

  if isDeputy then
    room:setPlayerProperty(player, "deputyGeneral", new_general)
    room:setPlayerMark(player, "__heg_deputy", new_general)
  else
    room:setPlayerProperty(player, "general", new_general)
    room:setPlayerMark(player, "__heg_general", new_general)
  end

  player:filterHandcards()
  room:sendLog{
    type = "#GeneralRemoved",
    from = player.id,
    arg = isDeputy and "deputyGeneral" or "mainGeneral",
    arg2 = orig,
  }
  room:returnToGeneralPile({orig})

  logic:trigger(HegUtil.GeneralRemoved, player, rgdata)
end

return RemoveGeneral
