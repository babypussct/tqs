local congcha = fk.CreateSkill {
  name = "ld__congcha",
}

Fk:loadTranslationTable {
  ["ld__congcha"] = "聪察",
  [":ld__congcha"] = "准备阶段，你可以选择一名未确定势力的角色，然后直到你的下回合开始，当其首次明置武将牌后，若其确定的势力与你的势力："..
  "相同，你与其各摸两张牌；不同，其失去1点体力。摸牌阶段，若所有角色均已确定势力，你可以多摸两张牌。",

  ["#ld__congcha-choose"] = "聪察：选择一名未确定势力的角色，其亮将后根据势力是否与你相同执行效果",
  ["@@ld__congcha"] = "聪察",
  ["#ld__congcha-draw"] = "聪察：你可以多摸两张牌",

  ["$ld__congcha1"] = "窥一斑而知全豹。",
  ["$ld__congcha2"] = "问一事则明其心。",
}

local H = require "packages.hegemony.util"

congcha:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(congcha.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return H.getGeneralsRevealedNum(p) == 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return H.getGeneralsRevealedNum(p) == 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ld__congcha-choose",
      skill_name = congcha.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:addTableMarkIfNeed(to, "@@ld__congcha", player)
  end,
})

congcha:addEffect(fk.GeneralRevealed, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(target:getTableMark("@@ld__congcha"), player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { target })
    room:removeTableMark(target, "@@ld__congcha", player)
    if H.compareKingdomWith(player, target) then
      player:drawCards(2, congcha.name)
      if not target.dead then
        target:drawCards(2, congcha.name)
      end
    else
      if not target.dead then
        room:loseHp(target, 1, congcha.name, player)
      end
    end
  end,
})

congcha:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@ld__congcha", player)
    end
  end,
})

congcha:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(congcha.name) and
      table.every(player.room.alive_players, function(p)
        return H.getGeneralsRevealedNum(p) > 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = congcha.name,
      prompt = "#ld__congcha-draw",
    })
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

congcha:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@ld__congcha", player)
  end
end)

return congcha
