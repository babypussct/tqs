local fujil = fk.CreateSkill {
  name = "fujil",
}

Fk:loadTranslationTable {
  ["fujil"] = "缚己",
  [":fujil"] = "每轮限一次，其他角色出牌阶段开始时，你可以令其观看你的手牌。若如此做，本回合结束时，你回复1点体力并摸三张牌；"..
  "本轮你成为其他角色使用牌的目标时，你可以将所有手牌交给一名其他角色并令此牌无效。",

  ["#fujil-invoke"] = "缚己：是否令 %dest 观看你的手牌？",
  ["@@fujil-round"] = "缚己",
  ["#fujil-give"] = "缚己：你可以交给一名角色所有手牌，令此%arg无效",

  ["$fujil1"] = "将军，妾这儿媳，可合您心意？",
  ["$fujil2"] = "自缚双臂，效赧王衔玉，求曹公怜惜。",
}

fujil:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(fujil.name) and target.phase == Player.Play and
      not player:isKongcheng() and not target.dead and
      player:usedEffectTimes(fujil.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = fujil.name,
      prompt = "#fujil-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:viewCards(target, {
      cards = player:getCardIds("h"),
      skill_name = fujil.name,
      prompt = "$ViewCardsFrom:"..player.id,
    })

    room:setPlayerMark(player, "@@fujil-round", 1)
    room:setPlayerMark(player, "fujil_used-turn", 1)
  end,
})

fujil:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:isAlive() and
      player:getMark("@@fujil-round") > 0 and
      not player:isKongcheng() and
      data.from ~= player and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#fujil-give:::"..data.card:toLogString(),
      skill_name = fujil.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:moveCardTo(player:getCardIds("h"), Card.PlayerHand, event:getCostData(self).tos[1], fk.ReasonGive, fujil.name, nil, false, player)
    data.use.nullifiedTargets = table.simpleClone(room.players)
  end,
})

fujil:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:getMark("fujil_used-turn") > 0 and player:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = fujil.name,
    }
    if not player.dead then
      player:drawCards(3, fujil.name)
    end
  end,
})

return fujil
