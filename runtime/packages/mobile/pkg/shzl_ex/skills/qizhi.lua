
local qizhi = fk.CreateSkill {
  name = "m_ex__qizhi",
  tags = { Skill.Charge },
  max_branches_use_time = function(self, player)
    local ret = {}
    for _, to in ipairs(Fk:currentRoom().players) do
      ret[tostring(to.id)] = {
        [Player.HistoryPhase] = 1,
      }
    end
    return ret
  end,
}

Fk:loadTranslationTable{
  ["m_ex__qizhi"] = "奇制",
  [":m_ex__qizhi"] = "蓄力技（1/2），出牌阶段每名角色限一次，你可以消耗1点蓄力点，令一名角色摸两张牌，" ..
  "然后本回合你使用基本牌或普通锦囊牌指定目标后，你依次观看本回合因此摸牌的角色的手牌并弃置其一张牌。",

  ["#m_ex__qizhi"] = "奇制：消耗1点蓄力点，令一名角色摸两张牌",
  ["#m_ex__qizhi-discard"] = "奇制：弃置 %dest 一张牌",

  ["$m_ex__qizhi1"] = "兵谋欲以奇胜，贵在临阵之判！",
  ["$m_ex__qizhi2"] = "将有专擅之权，方能临机制胜。",
  ["$m_ex__qizhi3"] = "今非缓成之功，当先夺争城之利也！",
  ["$m_ex__qizhi4"] = "先发有夺民之望，此用兵之势也！",
}

local U = require "packages.utility.utility"

qizhi:addEffect("active", {
  prompt = "#m_ex__qizhi",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("skill_charge") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and
      qizhi:withinBranchTimesLimit(player, tostring(to_select.id), Player.HistoryPhase)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:addSkillBranchUseHistory(qizhi.name, tostring(target.id), 1)
    room:addTableMarkIfNeed(player, "m_ex__qizhi-turn", target)
    U.skillCharged(player, -1)
    target:drawCards(2, qizhi.name)
  end,
})

qizhi:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qizhi.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data.firstTarget and
      player:getMark("m_ex__qizhi-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player:getTableMark("m_ex__qizhi-turn")) do
      if not p:isNude() then
        if p == player then
          room:askToDiscard(player, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = qizhi.name,
            prompt = "#m_ex__qizhi-discard::"..player.id,
            cancelable = false,
          })
        else
          local card_data = {}
          if not p:isKongcheng() then
            table.insert(card_data, { "$Hand", p:getCardIds("h") })
          end
          if #p:getCardIds("e") > 0 then
            table.insert(card_data, { "$Equip", p:getCardIds("e") })
          end
          local card = room:askToChooseCard(player, {
            target = p,
            flag = { card_data = card_data },
            skill_name = qizhi.name,
            prompt = "#m_ex__qizhi-discard::"..p.id,
          })
          room:throwCard(card, qizhi.name, p, player)
        end
        if player.dead then return end
      end
    end
  end,
})

qizhi:addAcquireEffect(function (self, player)
  U.skillCharged(player, 1, 2)
end)

qizhi:addLoseEffect(function (self, player)
  U.skillCharged(player, -1, -2)
end)

return qizhi
