---@class HegUtil
local HegUtil = require "packages.hegemony.utilevent._base"
--- GeneralRemoveData 描述和移除武将牌有关的数据
---@class GeneralRemoveDataSpec
---@field public who ServerPlayer @ 被移除武将的角色
---@field public isDeputy? boolean @ 是否是副将
---@field public origName? string @ 被移除武将的名称
---@field public skillName? string @ 触发移除武将的技能名

---@class HegUtil.GeneralRemoveData: GeneralRemoveDataSpec, TriggerData
HegUtil.GeneralRemoveData = TriggerData:subclass("GeneralRemoveData")

--- 移除武将牌TriggerEvent
---@class HegUtil.GeneralRemoveEvent: TriggerEvent
---@field public data HegUtil.GeneralRemoveData
HegUtil.GeneralRemoveEvent = TriggerEvent:subclass("GeneralRemoveEvent")

--- 移除武将牌时
---@class HegUtil.GeneralRemoving: HegUtil.GeneralRemoveEvent
HegUtil.GeneralRemoving = HegUtil.GeneralRemoveEvent:subclass("HegUtil.GeneralRemoving")
--- 移除武将牌后
---@class HegUtil.GeneralRemoved: HegUtil.GeneralRemoveEvent
HegUtil.GeneralRemoved = HegUtil.GeneralRemoveEvent:subclass("HegUtil.GeneralRemoved")

---@alias GeneralRemoveTrigFunc fun(self: TriggerSkill, event: HegUtil.GeneralRemoveEvent,
---  target: ServerPlayer, player: ServerPlayer, data: HegUtil.GeneralRemoveData):any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: HegUtil.GeneralRemoveEvent,
---  data: TrigSkelSpec<GeneralRemoveTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton

--- 移除武将牌
---@param player ServerPlayer
---@param isDeputy? boolean @ 是否为副将，默认主将
function HegUtil.removeGeneral(player, isDeputy)
  local data = HegUtil.GeneralRemoveData:new{
    who = player,
    isDeputy = isDeputy or false
  }
  local event = HegUtil.GameEvent.RemoveGeneral:create(data)
  local _, ret = event:exec()
  return ret
end

-- 初始化事件
local RemoveGeneral = require "packages.hegemony.utilevent.events.remove_general"
HegUtil.GameEvent.RemoveGeneral = RemoveGeneral

Fk:loadTranslationTable{
  ["#GeneralRemoved"] = "%from 移除了 %arg %arg2",
  ["removeMain"] = "移除主将 %arg",
  ["removeDeputy"] = "移除副将 %arg",
}