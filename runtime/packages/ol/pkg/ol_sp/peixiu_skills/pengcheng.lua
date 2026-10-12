local pengcheng = fk.CreateSkill {
  name = "peixiu_pengcheng",
}

Fk:loadTranslationTable {
  ["peixiu_pengcheng"] = "彭城",
  [":peixiu_pengcheng"] = "你获得此技能后，可以令一名其他角色交给你一张牌，然后其回复1点体力。",

  ["#peixiu_pengcheng-choose"] = "彭城：选择一名其他角色，其交给你一张牌，然后其回复1点体力",
  ["#peixiu_pengcheng-give"] = "彭城：请交给 %src 一张牌，你回复1点体力",
}

pengcheng:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(pengcheng.name) and data.skill.name == pengcheng.name and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = pengcheng.name,
      prompt = "#peixiu_pengcheng-choose",
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
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = pengcheng.name,
      prompt = "#peixiu_pengcheng-give:"..player.id,
      cancelable = false,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, pengcheng.name, nil, false, to)
    if not to.dead then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = pengcheng.name,
      }
    end
  end
})

return pengcheng
