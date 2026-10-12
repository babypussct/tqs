local lujiang = fk.CreateSkill {
  name = "peixiu_lujiang",
}

Fk:loadTranslationTable {
  ["peixiu_lujiang"] = "庐江",
  [":peixiu_lujiang"] = "你获得此技能后，你可以拼点，赢的角色摸两张牌。",

  ["#peixiu_lujiang-choose"] = "庐江：选择一名角色拼点，赢的角色摸两张牌",
}

lujiang:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lujiang.name) and data.skill.name == lujiang.name and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = lujiang.name,
      cancelable = true,
      prompt = "#peixiu_lujiang-choose",
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({ to }, lujiang.name)
    local winner = pindian.results[to].winner
    if winner and not winner.dead then
      winner:drawCards(2, lujiang.name)
    end
  end
})

return lujiang
