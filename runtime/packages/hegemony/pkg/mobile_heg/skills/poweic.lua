
local poweic = fk.CreateSkill {
  name = "m_heg__poweic",
}

Fk:loadTranslationTable{
  ["m_heg__poweic"] = "迫威",
  [":m_heg__poweic"] = "一名角色叠置或横置时，你可以改为暗置其主或副将并摸一张牌，以此法暗置的武将牌本回合无法明置。",

  ["#m_heg__poweic-turnover"] = "迫威：%dest 即将翻面，你可以改为暗置其一张武将牌并摸一张牌",
  ["#m_heg__poweic-chain"] = "迫威：%dest 即将横置，你可以改为暗置其一张武将牌并摸一张牌",

  ["$m_heg__poweic1"] = "朕所欲为之事，谁敢言他？",
  ["$m_heg__poweic2"] = "不为朕喜，那便无人能保。",
  ["$m_heg__poweic3"] = "汝负朕在先，休怪朕弃汝于市！",
  ["$m_heg__poweic4"] = "骨肉情深，好；永世不见，更好。",
}

local H = require "packages.hegemony.util"

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasShownSkill(poweic.name) and
      not data.prevented and (event == fk.BeforeTurnOver and target.faceup or not target.chained) and
      (target.general ~= "anjiang" or (target.deputyGeneral ~= "" and target.deputyGeneral ~= "anjiang"))
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = poweic.name,
      prompt = "#m_heg__poweic-"..(event == fk.BeforeTurnOver and "turnover" or "chain").."::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.prevented = true
    local isDeputy = H.doHideGeneral(room, player, target, poweic.name)
    room:addTableMark(target, MarkEnum.RevealProhibited .. "-turn", isDeputy and "d" or "m")
    if not player.dead then
      player:drawCards(1, poweic.name)
    end
  end,
}

poweic:addEffect(fk.BeforeTurnOver, spec)
poweic:addEffect(fk.BeforeChainStateChange, spec)

return poweic
