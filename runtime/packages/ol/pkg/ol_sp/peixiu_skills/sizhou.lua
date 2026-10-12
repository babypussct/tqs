local sizhou = fk.CreateSkill {
  name = "peixiu_sizhou",
}

Fk:loadTranslationTable {
  ["peixiu_sizhou"] = "司州",
  [":peixiu_sizhou"] = "你获得此技能后，可以获得一名角色一张手牌。",

  ["#peixiu_sizhou-choose"] = "司州：选择一名角色，获得其一张手牌",
}

sizhou:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(sizhou.name) and data.skill.name == sizhou.name and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = sizhou.name,
      prompt = "#peixiu_sizhou-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = sizhou.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, sizhou.name, nil, false, player)
  end
})

return sizhou
