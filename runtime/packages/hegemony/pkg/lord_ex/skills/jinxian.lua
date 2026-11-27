
local jinxian = fk.CreateSkill {
  name = "ld__jinxian",
}

Fk:loadTranslationTable {
  ["ld__jinxian"] = "近陷",
  [":ld__jinxian"] = "你明置此武将牌的回合结束时，你可以对任意名本回合明置过武将牌的其他角色各造成1点伤害。",

  ["#ld__jinxian-choose"] = "近陷：你可以对其中任意名角色各造成1点伤害",

  ["$ld__jinxian1"] = "如此荒辈之徒为主，成何用也。",
  ["$ld__jinxian2"] = "公既如此，恕在下诚难留之。",
}

jinxian:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jinxian.name) and
      player:getMark("ld__jinxian_invoke-turn") > 0 and
      table.find(player:getTableMark("ld__jinxian_targets-turn"), function (p)
        return p ~= player and not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getTableMark("ld__jinxian_targets-turn"), function (p)
        return p ~= player and not p.dead
      end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#ld__jinxian-choose",
      skill_name = jinxian.name,
      cancelable = true
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
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = jinxian.name,
        }
      end
    end
  end,
})

jinxian:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jinxian.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, "ld__jinxian_targets-turn", target)
    for _, v in pairs(data) do
      if table.contains(Fk.generals[v]:getSkillNameList(), jinxian.name) then
        room:setPlayerMark(player, "ld__jinxian_invoke-turn", 1)
        return
      end
    end
  end,
})

return jinxian
