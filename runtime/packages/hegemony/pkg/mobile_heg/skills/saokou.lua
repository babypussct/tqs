
local saokou = fk.CreateSkill{
  name = "m_heg__saokou",
}

Fk:loadTranslationTable{
  ["m_heg__saokou"] = "扫寇",
  [":m_heg__saokou"] = "每回合限一次，你使用伤害牌指定目标时，可以额外指定所有与任意当前目标同势力的角色为目标"..
  "（未确定势力则指定所有未确定势力角色为目标）。",

  ["#m_heg__saokou-invoke"] = "扫寇：你可以为此%arg额外指定所有%arg2势力角色为目标",
  ["#m_heg__saokou-nokingdom"] = "扫寇：你可以为此%arg额外指定所有未确定势力角色为目标",

  ["$m_heg__saokou1"] = "可还有逆我之人，策且一并扫之！",
  ["$m_heg__saokou2"] = "策领兵所至，群寇荡除！",
  ["$m_heg__saokou3"] = "英雄何忧兵寡，一虎岂畏群狼？",
  ["$m_heg__saokou4"] = "尔等既无顺意，我便一齐来攻！",
}

local H = require "packages.hegemony.util"

saokou:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(saokou.name) and
      data.card.is_damage_card and
      table.find(data:getExtraTargets({ bypass_distances = true }), function (p)
        return H.getKingdom(data.to) == H.getKingdom(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_distances = true }), function (p)
      return H.getKingdom(data.to) == H.getKingdom(p)
    end)
    local prompt = "#m_heg__saokou-nokingdom:::"..data.card:toLogString()
    if H.getKingdom(data.to) ~= "unknown" then
      prompt = "#m_heg__saokou-invoke:::"..data.card:toLogString()..":"..H.getKingdom(data.to)
    end
    if room:askToSkillInvoke(player, {
      skill_name = saokou.name,
      prompt = prompt,
    }) then
      room:sortByAction(targets)
      event:setCostData(self, { tos = targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos)
  end,
})

return saokou
