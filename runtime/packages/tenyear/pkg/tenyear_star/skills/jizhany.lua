local jizhany = fk.CreateSkill {
  name = "jizhany",
}

Fk:loadTranslationTable{
  ["jizhany"] = "急战",
  [":jizhany"] = "当你于回合内首次使用伤害牌指定第一个目标后，你可以令此牌对其中一个目标造成的伤害+2（本回合你每使用过一张非伤害牌，" ..
  "此数值便-1）。然后此牌结算结束后，若此牌未造成过伤害，其对你造成1点伤害。",

  ["#jizhany-choose"] = "急战：你可选择其中一名角色令此牌对其造成的伤害+%arg",
  ["#jizhany-invoke"] = "急战：你可令此牌对 %dest 造成的伤害+%arg",

  ["$jizhany1"] = "为将者，不可失其勇。",
  ["$jizhany2"] = "阵前休得啰嗦，哪个敢来领死？",
}

jizhany:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if
      not (
        target == player and
        player.phase ~= Player.NotActive and
        data.card.is_damage_card and
        data.firstTarget and
        player:hasSkill(jizhany.name)
      )
    then
      return false
    end

    local room = player.room
    local eventId = player:getMark("jizhany_record-turn")
    if eventId == 0 then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == player and use.card.is_damage_card then
          eventId = e.id
          room:setPlayerMark(player, "jizhany_record-turn", e.id)
          return true
        end
      end, Player.HistoryTurn)
    end

    return eventId == room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    table.forEach(data.use.tos, function(p)
      if p:isAlive() then
        table.insertIfNeed(targets, p)
      end
    end)

    if #targets == 0 then
      return false
    end

    local room = player.room
    local num = 2 - #room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
      local use = e.data
      return use.from == player and not use.card.is_damage_card
    end, Player.HistoryPhase)

    if #targets > 1 then
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = jizhany.name,
          prompt = "#jizhany-choose:::" .. num,
        }
      )

      if #tos > 0 then
        event:setCostData(self, { tos = tos, damageIncrease = num })
        return true
      end
    else
      if
        room:askToSkillInvoke(
          player,
          {
            skill_name = jizhany.name,
            prompt = "#jizhany-invoke::" .. targets[1].id .. ":" .. num
          }
        )
      then
        event:setCostData(self, { tos = targets, damageIncrease = num })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local damageIncrease = event:getCostData(self).damageIncrease

    data.extra_data = data.extra_data or {}
    data.extra_data.jizhanyMapper = { to, damageIncrease }
  end,
})

jizhany:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and data.by_user)  then
      return false
    end

    local effect = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if
      effect and
      (effect.data.extra_data or {}).jizhanyMapper and
      effect.data.extra_data.jizhanyMapper[1] == player
    then
      event:setCostData(self, { damageIncrease = effect.data.extra_data.jizhanyMapper[2] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(event:getCostData(self).damageIncrease)
  end,
})

jizhany:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      (data.extra_data or {}).jizhanyMapper and
      data.extra_data.jizhanyMapper[1]:isAlive() and
      not data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(data.extra_data.jizhanyMapper[1], { player })
    player.room:damage{
      from = data.extra_data.jizhanyMapper[1],
      to = player,
      damage = 1,
      skillName = jizhany.name,
    }
  end,
})

return jizhany
