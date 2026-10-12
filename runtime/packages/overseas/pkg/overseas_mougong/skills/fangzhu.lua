local fangzhu = fk.CreateSkill {
  name = "os_mou__fangzhu",
  related_skills = { "yuanbu" },
}

Fk:loadTranslationTable{
  ["os_mou__fangzhu"] = "放逐",
  [":os_mou__fangzhu"] = "每轮限一次，每个回合开始时，你可以令一名角色（不能为当前回合角色及其上家）与其下家交换座次；当你受到伤害后，" ..
  "若此为伤害来源本轮首次对你造成的伤害，你可以选择一项：1.令其非锁定技失效并获得技能〖远步〗直到其下个回合结束；" ..
  "2.令其不能使用或打出当前手牌直到其下个回合结束。",

  ["#os_mou__fangzhu-invoke"] = "放逐：你可令其中一名角色与其下家交换座次",
  ["os_mou__fangzhu_nullify"] = "令 %dest 非锁定技失效并获得“远步”直到其下个回合结束",
  ["os_mou__fangzhu_prohibit"] = "令 %dest 不能使用或打出当前手牌直到其下个回合结束",
  ["@@os_mou__fangzhu"] = "放逐",
  ["@@os_mou__fangzhu_prohibited-inhand"] = "放逐",

  ["$os_mou__fangzhu1"] = "爱卿之罪，其罪虽小，其心可诛。",
  ["$os_mou__fangzhu2"] = "孤闻仁主不兴肉刑，然爱卿之罪亦不可饶恕……",
}

fangzhu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(fangzhu.name) and
      player:usedEffectTimes(self.name, Player.HistoryRound) == 0 and
      table.find(player.room.alive_players, function(p)
        local current = player.room.current
        return p ~= current and p ~= current:getLastAlive() and p:getNextAlive() ~= nil
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      local current = room.current
      return p ~= current and p ~= current:getLastAlive() and p:getNextAlive() ~= nil
    end)

    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = fangzhu.name,
        prompt = "#os_mou__fangzhu-invoke"
      }
    )

    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local nextPlayer = to:getNextAlive()
    if not nextPlayer then
      return false
    end

    player.room:swapSeat(to, nextPlayer)
  end,
})

fangzhu:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if
      not (
        target == player and
        data.from and
        data.from:isAlive() and
        player:hasSkill(fangzhu.name)
      )
    then
      return false
    end

    local room = player.room
    local damageMapper = player:getTableMark("os_mou__fangzhu_record-round-noclear")
    if not damageMapper[tostring(data.from.id)] then
      room.logic:getActualDamageEvents(1, function(e)
        if e.data.from == data.from and e.data.to == player then
          damageMapper[tostring(data.from.id)] = e.id
          room:setPlayerMark(player, "os_mou__fangzhu_record-round-noclear", damageMapper)
          return true
        end
      end, Player.HistoryRound)
    end

    return damageMapper[tostring(data.from.id)] == room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {
      "os_mou__fangzhu_nullify::" .. data.from.id,
      "os_mou__fangzhu_prohibit::" .. data.from.id,
      "Cancel",
    }
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = fangzhu.name,
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if room.current == data.from then
      room:setPlayerMark(data.from, "os_mou__fangzhu-turn", 1)
    end
    if choice:startsWith("os_mou__fangzhu_nullify") then
      room:setPlayerMark(data.from, "@@os_mou__fangzhu", 1)
      room:handleAddLoseSkills(data.from, "yuanbu")
    else
      table.forEach(data.from:getCardIds("h"), function(id)
        room:setCardMark(Fk:getCardById(id), "@@os_mou__fangzhu_prohibited-inhand", 1)
      end)
    end
  end,
})

fangzhu:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  priority = -1,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:getMark("os_mou__fangzhu-turn") == 0 and
      (
        player:getMark("@@os_mou__fangzhu") > 0 or
        table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@os_mou__fangzhu_prohibited-inhand") > 0
        end)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@os_mou__fangzhu") > 0 then
      room:setPlayerMark(player, "@@os_mou__fangzhu", 0)
      room:handleAddLoseSkills(player, "-yuanbu")
    end

    table.forEach(player:getCardIds("h"), function(id)
      room:setCardMark(Fk:getCardById(id), "@@os_mou__fangzhu_prohibited-inhand", 0)
    end)
  end,
})

fangzhu:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      (
        player:getMark("@@os_mou__fangzhu") > 0 or
        table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@os_mou__fangzhu_prohibited-inhand") > 0
        end)
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@os_mou__fangzhu") > 0 then
      room:setPlayerMark(player, "@@os_mou__fangzhu", 0)
      room:handleAddLoseSkills(player, "-yuanbu", nil, false, true)
    end

    table.forEach(player:getCardIds("h"), function(id)
      room:setCardMark(Fk:getCardById(id), "@@os_mou__fangzhu_prohibited-inhand", 0)
    end)
  end,
})

fangzhu:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return
      not skill:hasTag(Skill.Compulsory) and
      skill:isPlayerSkill(from) and
      from:getMark("@@os_mou__fangzhu") > 0
  end,
})

fangzhu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return
      card and
      Fk:currentRoom():getCardOwner(card) == player and
      table.find(Card:getIdList(card), function(id) return
        Fk:getCardById(id):getMark("@@os_mou__fangzhu_prohibited-inhand") > 0
      end)
  end,
  prohibit_response = function(self, player, card)
    return
      card and
      Fk:currentRoom():getCardOwner(card) == player and
      table.find(Card:getIdList(card), function(id) return
        Fk:getCardById(id):getMark("@@os_mou__fangzhu_prohibited-inhand") > 0
      end)
  end,
})

return fangzhu
