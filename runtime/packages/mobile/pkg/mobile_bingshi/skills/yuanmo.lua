local yuanmo = fk.CreateSkill {
  name = "mobile__yuanmo",
}

Fk:loadTranslationTable{
  ["mobile__yuanmo"] = "远谟",
  [":mobile__yuanmo"] = "每回合限两次，准备阶段，或当你受到伤害后，你可以移动场上的一张牌，然后你可以令因此失去牌的角色摸X张牌"..
  "（X为其攻击范围内因此减少的角色数，至多为5）。",

  ["#mobile__yuanmo-move"] = "远谟：你可以移动场上一张牌，然后可以令失去牌的角色摸牌",
  ["#mobile__yuanmo-draw"] = "远谟：是否令 %dest 摸%arg张牌？",

  ["$mobile__yuanmo1"] = "孙策据长江之险，兵精粮广，未可图也。",
  ["$mobile__yuanmo2"] = "今当先伐刘备，然后图取孙策未迟。",
  ["$mobile__yuanmo3"] = "某今献一计，可使刘备即日就擒。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askToChooseToMoveCardInBoard(player, {
      skill_name = yuanmo.name,
      prompt = "#mobile__yuanmo-move",
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    local count1 = #table.filter(room.alive_players, function (p)
      return targets[1]:inMyAttackRange(p)
    end)
    local count2 = #table.filter(room.alive_players, function (p)
      return targets[2]:inMyAttackRange(p)
    end)
    local result = room:askToMoveCardInBoard(player, {
      skill_name = yuanmo.name,
      target_one = targets[1],
      target_two = targets[2],
    })
    if player.dead or result == nil or result.from.dead then return end
    local count = #table.filter(room.alive_players, function (p)
      return result.from:inMyAttackRange(p)
    end)
    local n = result.from == targets[1] and count1 - count or count2 - count
    n = math.min(n, 5)
    if n > 0 and
      room:askToSkillInvoke(player, {
        skill_name = yuanmo.name,
        prompt = "#mobile__yuanmo-draw::"..result.from.id..":"..n,
      }) then
      result.from:drawCards(n, yuanmo.name)
    end
  end,
}

yuanmo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanmo.name) and player.phase == Player.Start and
      #player.room:canMoveCardInBoard() > 0 and player:usedSkillTimes(yuanmo.name, Player.HistoryTurn) < 2
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
yuanmo:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanmo.name) and
      #player.room:canMoveCardInBoard() > 0 and player:usedSkillTimes(yuanmo.name, Player.HistoryTurn) < 2
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return yuanmo
