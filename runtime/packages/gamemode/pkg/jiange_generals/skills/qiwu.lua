local qiwu = fk.CreateSkill {
  name = "jiange__qiwu",
}

Fk:loadTranslationTable{
  ["jiange__qiwu"] = "栖梧",
  [":jiange__qiwu"] = "当你使用♣牌时，你可以令一名友方角色回复1点体力。",

  ["#jiange__qiwu-choose"] = "栖梧：你可以令一名友方角色回复1点体力",
}

qiwu:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiwu.name) and data.card.suit == Card.Club and
      table.find(player:getFriends(), function (p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getFriends(), function (p)
      return p:isWounded()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#jiange__qiwu-choose",
      skill_name = qiwu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = event:getCostData(self).tos[1],
      num = 1,
      recoverBy = player,
      skillName = qiwu.name,
    }
  end,
})

return qiwu
