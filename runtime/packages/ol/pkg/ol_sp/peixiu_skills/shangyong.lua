local shangyong = fk.CreateSkill {
  name = "peixiu_shangyong",
}

Fk:loadTranslationTable {
  ["peixiu_shangyong"] = "上庸",
  [":peixiu_shangyong"] = "你获得此技能后，可以与一名其他角色各摸一张牌。",

  ["#peixiu_shangyong-choose"] = "上庸：选择一名其他角色，与其各摸一张牌",
}

shangyong:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shangyong.name) and data.skill.name == shangyong.name and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = shangyong.name,
      prompt = "#peixiu_shangyong-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    player:drawCards(1, shangyong.name)
    if not to.dead then
      to:drawCards(1, shangyong.name)
    end
  end
})

return shangyong
