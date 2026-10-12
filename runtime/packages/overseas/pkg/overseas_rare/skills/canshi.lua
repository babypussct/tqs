local osCanshi = fk.CreateSkill {
  name = "os__canshi"
}

Fk:loadTranslationTable{
  ["os__canshi"] = "蚕食",
  [":os__canshi"] = "①当一名角色使用基本牌或普通锦囊牌指定你为唯一目标时，若其有“傀”，你可取消之，然后其弃1枚“傀”。" ..
  "②你使用基本牌或普通锦囊牌仅选择一名角色为目标时，你可令任意名带有“傀”的角色也成为目标，然后这些角色弃1枚“傀”。",

  ["@@os__puppet"] = "傀",
  ["#os__canshi"] = "蚕食：你可取消【%arg】的目标，然后 %dest 弃“傀”",
  ["#os__canshi-targets"] = "蚕食：你可令任意名有“傀”的角色也成为目标，然后这些角色弃“傀”",

  ["$os__canshi1"] = "此患不足为惧，可蚕食而尽。",
  ["$os__canshi2"] = "小则蚕食，大则溃坝。",
}

osCanshi:addEffect(fk.TargetConfirming, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osCanshi.name) and
      data:isOnlyTarget(player) and
      data.from:getMark("@@os__puppet") > 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = osCanshi.name,
        prompt = "#os__canshi::" .. data.from.id .. ":" .. data.card.name
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osCanshi.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 1)
    room:notifySkillInvoked(player, skillName, "defensive")
    data:cancelTarget(data.to)
    room:removePlayerMark(data.from, "@@os__puppet")
  end,
})

osCanshi:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osCanshi.name) and
      #(data.tos or {}) > 0 and
      data:isOnlyTarget(data.tos[1]) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      table.find(data:getExtraTargets({ bypass_times = true, bypass_distances = true }), function (p)
        return p:getMark("@@os__puppet") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_times = true, bypass_distances = true }), function (p)
      return p:getMark("@@os__puppet") > 0
    end)
    local tos = room:askToChoosePlayers(player,{
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#os__canshi-targets",
      skill_name = osCanshi.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osCanshi.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 2)
    room:notifySkillInvoked(player, skillName, "special")
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      data:addTarget(p)
      room:removePlayerMark(p, "@@os__puppet")
    end
  end
})

return osCanshi
