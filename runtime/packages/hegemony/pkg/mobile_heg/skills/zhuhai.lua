
local zhuhai = fk.CreateSkill{
  name = "m_heg__zhuhai",
}

Fk:loadTranslationTable{
  ["m_heg__zhuhai"] = "诛害",
  [":m_heg__zhuhai"] = "其他角色的结束阶段，若该角色于此回合内造成过伤害，你可以对其使用一张无距离限制的【杀】。"..
  "若其本回合对与你势力相同的角色造成过伤害，则你以此法使用【杀】无视其防具，且其使用【闪】响应此【杀】后，其须弃置一张牌。",

  ["#m_heg__zhuhai-invoke"] = "诛害：是否发动“诛害”，可以对 %dest 使用【杀】？",
  ["#m_heg__zhuhai-use"] = "诛害：你可以对 %dest 使用【杀】",

  ["$m_heg__zhuhai1"] = "今日当要替天行道。",
  ["$m_heg__zhuhai2"] = "我容得你，天不容你。",
}

local H = require "packages.hegemony.util"

zhuhai:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player ~= target and player:hasSkill(zhuhai.name) and target.phase == Player.Finish and
      not target.dead and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if player:hasShownSkill(zhuhai.name) then
      local use = room:askToUseCard(player, {
        skill_name = zhuhai.name,
        pattern = "slash",
        prompt = "#m_heg__zhuhai-use::"..target.id,
        cancelable = true,
        extra_data = {
          bypass_times = true,
          bypass_distances = true,
          extraUse = true,
          must_targets = { target.id },
        },
      })
      if use then
        event:setCostData(self, { extra_data = use })
        return true
      end
    else
      return room:askToSkillInvoke(player, {
        skill_name = zhuhai.name,
        prompt = "#m_heg__zhuhai-invoke::"..target.id,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = (event:getCostData(self) or {}).extra_data
    if use == nil then
      use = room:askToUseCard(player, {
        skill_name = zhuhai.name,
        pattern = "slash",
        prompt = "#m_heg__zhuhai-use::"..target.id,
        cancelable = true,
        extra_data = {
          bypass_times = true,
          bypass_distances = true,
          extraUse = true,
          must_targets = { target.id },
        },
      })
    end
    if use then
      if #room.logic:getActualDamageEvents(1, function(e)
          return e.data.from == target and H.compareKingdomWith(player, e.data.to)
        end, Player.HistoryTurn) > 0 then
        use.extra_data = use.extra_data or {}
        use.extra_data.m_heg__zhuhai = target
      end
      room:useCard(use)
    end
  end,
})

zhuhai:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return data.to == player and (data.extra_data or {}).m_heg__zhuhai == player and not player.dead
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

zhuhai:addEffect(fk.CardEffectCancelledOut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.to == player and not player.dead and not player:isNude() and
      (data.extra_data or {}).m_heg__zhuhai == player
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhuhai.name,
      cancelable = false,
    })
  end,
})

return zhuhai
