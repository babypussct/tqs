local yingjian = fk.CreateSkill {
  name = "yingjian",
}

Fk:loadTranslationTable{
  ["yingjian"] = "影箭",
  [":yingjian"] = "准备阶段，你可以视为使用一张无距离限制的【杀】。",

  ["#yingjian-choose"] = "影箭：你可以视为使用无视距离的【杀】",

  ["$yingjian1"] = "翩翩逸云端，仿若桃花仙。",
  ["$yingjian2"] = "没牌，又有何不可能的？",
}

yingjian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingjian.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canUseTo(slash, p, {bypass_distances = true, bypass_times = true})
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = max_num,
      targets = targets,
      skill_name = yingjian.name,
      prompt = "#yingjian-choose",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    room:sortByAction(targets)
    room:useVirtualCard("slash", nil, player, targets, yingjian.name, true)
  end,
})

return yingjian
