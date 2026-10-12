local xiangyang = fk.CreateSkill {
  name = "peixiu_xiangyang",
}

Fk:loadTranslationTable {
  ["peixiu_xiangyang"] = "襄阳",
  [":peixiu_xiangyang"] = "你获得此技能后，可以移动场上一张牌。",

  ["#peixiu_xiangyang-choose"] = "襄阳：你可以移动场上一张牌",
}

xiangyang:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiangyang.name) and data.skill.name == xiangyang.name and
      #player.room:canMoveCardInBoard() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askToChooseToMoveCardInBoard(player, {
      skill_name = xiangyang.name,
      prompt = "#peixiu_xiangyang-choose",
      cancelable = true
    })
    if #targets > 0 then
      event:setCostData(self, { tos = targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local targets = event:getCostData(self).tos or {}
    player.room:askToMoveCardInBoard(player, {
      skill_name = xiangyang.name,
      target_one = targets[1],
      target_two = targets[2],
    })
  end
})

return xiangyang
