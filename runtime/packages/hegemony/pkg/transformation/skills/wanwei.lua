local wanwei = fk.CreateSkill{
  name = "ld__wanwei",
}

Fk:loadTranslationTable{
  ["ld__wanwei"] = "挽危",
  [":ld__wanwei"] = "每回合限一次，与你势力相同的其他角色进入濒死阶段后，你可以交给其至多三张牌，然后其脱离濒死阶段后，你摸等量的牌。",

  ["#ld__wanwei-invoke"] = "挽危：你可以交给 %dest 至多三张牌，其脱离濒死状态后你摸等量牌",

  ["$ld__wanwei1"] = "梁、沛之间，非子廉无有今日。",
  ["$ld__wanwei2"] = "正使祸至，共死何苦！",
}

local H = require "packages.hegemony.util"

wanwei:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wanwei.name) and target ~= player and H.compareKingdomWith(target, player) and
    not player:isNude() and player:usedSkillTimes(wanwei.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 3,
      skill_name = wanwei.name,
      cancelable = true,
      prompt = "#ld__wanwei-invoke::" .. target.id,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, wanwei.name, nil, false, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.new_ld__wanwei = data.extra_data.new_ld__wanwei or {}
    table.insert(data.extra_data.new_ld__wanwei, {player.id, #cards})
  end,
})

wanwei:addEffect(fk.AfterDying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not target.dead and not player.dead and data.extra_data and
      data.extra_data.new_ld__wanwei and
      table.find(data.extra_data.new_ld__wanwei, function(info)
        return info[1] == player.id
      end)
  end,
  on_use = function(self, event, target, player, data)
    local info = table.find(data.extra_data.new_ld__wanwei, function(info)
      return info[1] == player.id
    end)
    if info == nil then return end
    player:drawCards(info[2], wanwei.name)
  end,
})

return wanwei
