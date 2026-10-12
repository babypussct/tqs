local osBaizu = fk.CreateSkill {
  name = "os__baizu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__baizu"] = "败族",
  [":os__baizu"] = "锁定技，结束阶段，若你已受伤且有手牌，你须选择X名其他角色，令你与这些角色同时弃置一张手牌，" ..
  "然后你对弃置与你相同类型牌的其他角色造成1点伤害（X为你的体力值）。<a href='os__veteran'>历战</a>：X+1。",

  ["@os__baizu"] = "败族",
  ["#os__baizu-ask"] = "败族：选择 %arg 名其他角色，你和这些角色各弃置一张手牌",
  ["#os__baizu-discard"] = "败族：请弃置一张手牌，若与 %src 类别相同则受到伤害！",

  ["$os__baizu1"] = "今袁氏之势，岂独因我？",
  ["$os__baizu2"] = "长幼之序不明，何惜操戈以正！",
}

osBaizu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player == target and
      target:hasSkill(osBaizu.name) and
      player.phase == Player.Finish and
      player:isWounded() and
      not player:isKongcheng() and
      (player.hp + player:getMark("@os__baizu")) > 0 and
      table.find(player.room.alive_players, function(p)
        return p ~= player and not p:isKongcheng()
      end)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osBaizu.name
    local room = player.room
    local x = player.hp + player:getMark("@os__baizu")
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and not p:isKongcheng()
    end)
    if #targets > x then
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = x,
        max_num = x,
        prompt = "#os__baizu-ask:::" .. x,
        skill_name = osBaizu.name,
        cancelable = false,
      })
    end
    table.insert(targets, player)
    room:doIndicate(player, targets)

    local cardsMap = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      skill_name = skillName,
      cancelable = false,
      prompt = "#os__baizu-discard:"..player.id,
      will_throw = true,
    })
    local moveInfos = {}
    local victims = {}
    local cardType = #cardsMap[player] > 0 and Fk:getCardById(cardsMap[player][1]).type or 0
    for _, p in ipairs(targets) do
      local throw = cardsMap[p]
      if #throw > 0 then
        if p ~= player and Fk:getCardById(throw[1]).type == cardType then
          table.insert(victims, p)
        end
        table.insert(moveInfos, {
          ids = throw,
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p,
          skillName = skillName,
        })
      end
    end
    if #moveInfos == 0 then
      return false
    end

    room:moveCards(table.unpack(moveInfos))
    if #victims == 0 then
      return false
    end

    room:sortByAction(victims)
    for _, p in ipairs(victims) do
      if p:isAlive() then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = skillName,
        }
      end
    end
  end,
})

osBaizu:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(osBaizu.name) and player:usedSkillTimes(osBaizu.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__baizu")
  end,
})

osBaizu:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@os__baizu", 0)
end)

return osBaizu
