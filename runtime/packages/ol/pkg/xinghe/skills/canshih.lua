
local canshih = fk.CreateSkill {
  name = "canshih",
}

Fk:loadTranslationTable{
  ["canshih"] = "蚕食",
  [":canshih"] = "当有“傀”的角色使用基本牌或普通锦囊牌指定你为唯一目标时，你可以取消之，然后其移除“傀”。" ..
  "当你使用基本牌或普通锦囊牌仅指定唯一目标时，你可以额外指定任意名有“傀”的角色为目标，然后其移除“傀”。",

  ["#canshih-cancel"] = "蚕食：你可以移去 %dest 的“傀”，取消此%arg目标",
  ["#canshih-add"] = "蚕食：你可以移去其他角色的“傀”，额外指定其为此%arg目标",

  ["$canshih1"] = "是你在召唤我吗？",
  ["$canshih2"] = "这片土地的人真是太有趣了。",
}

canshih:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(canshih.name) and
      data:isOnlyTarget(player) and data.from:getMark("@@puppet") > 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = canshih.name,
      prompt = "#canshih-cancel::" .. data.from.id .. ":" .. data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:cancelTarget(data.to)
    room:removePlayerMark(data.from, "@@puppet")
  end,
})

canshih:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(canshih.name) and
      data:isOnlyTarget(data.tos[1]) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      table.find(data:getExtraTargets({ bypass_times = true, bypass_distances = true }), function (p)
        return p:getMark("@@puppet") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_times = true, bypass_distances = true }), function (p)
      return p:getMark("@@puppet") > 0
    end)
    local tos = room:askToChoosePlayers(player,{
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#canshih-add:::"..data.card:toLogString(),
      skill_name = canshih.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
      room:removePlayerMark(p, "@@puppet", 1)
    end
  end
})

return canshih
