local hanzhong = fk.CreateSkill {
  name = "peixiu_hanzhong",
}

Fk:loadTranslationTable {
  ["peixiu_hanzhong"] = "汉中",
  [":peixiu_hanzhong"] = "你获得此技能后，可以与一名其他角色交换手牌。",

  ["#peixiu_hanzhong-choose"] = "汉中：选择一名其他角色交换手牌",
}

hanzhong:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(hanzhong.name) and data.skill.name == hanzhong.name and
      (not player:isKongcheng() or
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    if player:isKongcheng() then
      targets = table.filter(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = hanzhong.name,
      prompt = "#peixiu_hanzhong-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:swapAllCards(player, { player, to }, hanzhong.name)
  end
})

return hanzhong
