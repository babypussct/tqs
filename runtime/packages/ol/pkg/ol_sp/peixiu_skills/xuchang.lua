local xuchang = fk.CreateSkill {
  name = "peixiu_xuchang",
}

Fk:loadTranslationTable {
  ["peixiu_xuchang"] = "许昌",
  [":peixiu_xuchang"] = "你获得此技能后，可令一名其他角色攻击范围增加至与你相同。",

  ["#peixiu_xuchang-choose"] = "许昌：选择一名其他角色，令其攻击范围增加至与你相同",
  ["@@peixiu_xuchang"] = "攻击范围+",
}

xuchang:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xuchang.name) and data.skill.name == xuchang.name and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:getAttackRange() > p:getAttackRange()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:getAttackRange() > p:getAttackRange()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xuchang.name,
      prompt = "#peixiu_xuchang-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    local my_range = player:getAttackRange()
    local his_range = to:getAttackRange()
    if my_range > his_range then
      local diff = my_range - his_range
      room:setPlayerMark(to, "@@peixiu_xuchang", diff)
    end
  end
})

xuchang:addEffect("targetmod", {
  extra_attack_range_func = function(self, player)
    return player:getMark("@@peixiu_xuchang") or 0
  end,
})

return xuchang
