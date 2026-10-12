---@class HegUtil
local HegUtil = require "packages.hegemony.utilevent._base"
--- GeneralTransformedData 描述和变更武将牌有关的数据
---@class GeneralTransformedDataSpec
---@field public who ServerPlayer @ 被移除武将的角色
---@field public isMain? boolean @ 是否是主将
---@field public origName? string @ 变更前武将的名称
---@field public isHidden? boolean @ 变更后是否暗置该武将
---@field public num? integer @ 选将数量，默认为3
---@field public skillName? string @ 触发变更武将的技能名

---@class HegUtil.GeneralTransformedData: GeneralTransformedDataSpec, TriggerData
HegUtil.GeneralTransformedData = TriggerData:subclass("GeneralTransformedData")

--- 变更武将牌TriggerEvent
---@class HegUtil.GeneralTransformedEvent: TriggerEvent
---@field public data HegUtil.GeneralTransformedData
HegUtil.GeneralTransformedEvent = TriggerEvent:subclass("GeneralTransformedEvent")

--- 变更武将牌时
---@class HegUtil.GeneralTransforming: HegUtil.GeneralTransformedEvent
HegUtil.GeneralTransforming = HegUtil.GeneralTransformedEvent:subclass("HegUtil.GeneralTransforming")
--- 变更武将牌后
---@class HegUtil.GeneralTransformed: HegUtil.GeneralTransformedEvent
HegUtil.GeneralTransformed = HegUtil.GeneralTransformedEvent:subclass("HegUtil.GeneralTransformed")

---@alias GeneralTransformedTrigFunc fun(self: TriggerSkill, event: HegUtil.GeneralTransformedEvent,
---  target: ServerPlayer, player: ServerPlayer, data: HegUtil.GeneralTransformedData):any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: HegUtil.GeneralTransformedEvent,
---  data: TrigSkelSpec<GeneralTransformedTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton

--- 变更武将牌
---@param room Room
---@param player ServerPlayer
---@param isMain boolean? @ 是否为主将，默认副将
---@param isHidden boolean? @ 是否暗置变更
---@param num? integer @ 选将数量，26规则默认为1，18规则默认为3（TODO?）
function HegUtil.transformGeneral(room, player, isMain, isHidden, num)
  local data = HegUtil.GeneralTransformedData:new{
    isMain = isMain,
    isHidden = isHidden,
    num = num,
  }
  if room.logic:trigger(HegUtil.GeneralTransforming, player, data) then return false end
  isMain = data.isMain
  isHidden = data.isHidden
  num = data.num
  local orig = isMain and player.general or player.deputyGeneral
  data.origName = orig
  num = num or 1
  if not orig then return false end
  if orig == "anjiang" then
    player:revealGeneral(not isMain, true)
    orig = isMain and player.general or player.deputyGeneral
  end
  local kingdom = player.kingdom
  if player:getMark("__heg_kingdom") ~= 0 then
    kingdom = player:getMark("__heg_kingdom")
  end
  if kingdom == "wild" then
    if player:getMark("__heg_init_kingdom") ~= 0 then
      kingdom = player:getMark("__heg_init_kingdom")
    end
  end
  local generals = room:findGenerals(function(g)
    return Fk.generals[g]:hasKingdom(kingdom)
  end, num)
  local general = num == 1 and generals[1] or
    room:askToChooseGeneral(player, {
      generals = generals,
      n = num,
      no_convert = true,
    }) --[[@as string]]
  table.removeOne(generals, general)
  table.insert(generals, orig)
  room:returnToGeneralPile(generals)
  room:changeHero(player, general, false, not isMain, not isHidden, false, false)
  --暗置变更
  if isHidden then
    player:hideGeneral(not isMain)
    room:sendLog{
      type = "#ChangeHiddenGeneral",
      from = player.id,
      arg = isMain and "mainGeneral" or "deputyGeneral",
      toast = true,
    }
  end
  room:setPlayerMark(player, isMain and "__heg_general" or "__heg_deputy", general)
  room.logic:trigger(HegUtil.GeneralTransformed, player, data)
end

Fk:loadTranslationTable{
  ["#ChangeHiddenGeneral"] = "%from 变更了 %arg（暗置）",
}