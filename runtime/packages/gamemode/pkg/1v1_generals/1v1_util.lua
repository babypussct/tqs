---@class Utility : Object
local Utility = {}

------------------------------------------------------------------------------------------------------

-- 流放一名角色（其必须流放区小于3且有剩余武将）
---@param player ServerPlayer @ 操作者
---@param to ServerPlayer @ 被流放的角色
---@return string|nil @ 返回被流放的武将名，无法流放返回nil
Utility.exilePlayer = function(player, to)
  local room = player.room
  local exiled_name = to.role == "lord" and "@&firstExiled" or "@&secondExiled"
  local exiled_generals = room:getBanner(exiled_name) or  {}
  if #exiled_generals > 2 then return nil end
  local rest_name = to.role == "lord" and "@&firstGenerals" or "@&secondGenerals"
  local rest_genrals = room:getBanner(rest_name) or {}
  if #rest_genrals == 0 then return nil end
  -- add prompt for general to exile
  local general = room:askToChooseGeneral(player, {
    generals = rest_genrals,
    n = 1,
    no_convert = true,
  })
  table.insert(exiled_generals, general)
  room:setBanner(exiled_name, exiled_generals)
  table.removeOne(rest_genrals, general)
  room:setBanner(rest_name, rest_genrals)
  return general
end

------------------------------------------------------------------------------------------------------
--- DebutData 数据
---@class DebutDataSpec
---@field public n integer @ 数量

---@class Utility.DebutData: DebutDataSpec, TriggerData
Utility.DebutData = TriggerData:subclass("DebutData")

--- TriggerEvent
---@class Utility.DebutTriggerEvent: TriggerEvent
---@field public data Utility.DebutData
Utility.DebutTriggerEvent = TriggerEvent:subclass("DebutEvent")

--- 登场时
---@class Utility.Debut: Utility.DebutTriggerEvent
Utility.Debut = Utility.DebutTriggerEvent:subclass("fk.Debut")

---@alias DebutTrigFunc fun(self: TriggerSkill, event: Utility.DebutTriggerEvent,
---  target: ServerPlayer, player: ServerPlayer, data: Utility.DebutData):any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: Utility.DebutTriggerEvent,
---  data: TrigSkelSpec<DebutTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton

return Utility
