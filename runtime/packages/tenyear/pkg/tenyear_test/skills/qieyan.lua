
local qieyan = fk.CreateSkill {
  name = "qieyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qieyan"] = "怯言",
  [":qieyan"] = "锁定技，你不能响应距离你为1的角色使用的牌。其他角色使用牌指定你为目标结算完毕后，本回合其与你计算距离+1，"..
  "若你因此脱离其攻击范围，你回复1点体力并摸两张牌。",

  ["$qieyan1"] = "",
  ["$qieyan2"] = "",
}

qieyan:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target:compareDistance(player, 1, "==") and player:hasSkill(qieyan.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player)
  end,
})

qieyan:addEffect(fk.CardUseFinished, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(qieyan.name) and
      table.contains(data.tos, player) and not target.dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local yes1 = target:inMyAttackRange(player)
    room:addTableMark(player, "qieyan-turn", target)
    if yes1 and not target:inMyAttackRange(player) then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = qieyan.name,
      }
      if player.dead then return end
      player:drawCards(2, qieyan.name)
    end
  end,
})

qieyan:addEffect("distance", {
  correct_func = function (self, from, to, card)
    return #table.filter(to:getTableMark("qieyan-turn"), function (p)
      return p == from
    end)
  end,
})

return qieyan
