local qiwu = fk.CreateSkill{
  name = "qiwul",
}

Fk:loadTranslationTable{
  ["qiwul"] = "绮武",
  [":qiwul"] = "出牌阶段限一次，你可弃置任意张牌，视为使用一张无距离和次数限制的【杀】，目标角色需弃置X张牌（X为你弃置牌的花色数）。"..
    "若你们因此弃置了牌：且包含【闪】，你获得弃置牌中的【闪】，且本回合不计入手牌上限；且不包含【闪】，此【杀】不可响应。",

  ["#qiwu"] = "绮武：弃置任意张牌，视为使用【杀】，且目标角色需弃置所选花色数牌",
  ["@@qiwul-inhand-turn"] = "绮武",

  ["$qiwul1"] = "此绮武也，岂是尔等蛮力可及？",
  ["$qiwul2"] = "方天画戟，亦能舞于巾帼之手！",
  ["$qiwul3"] = "驱驰良骥，当破万军。",
  ["$qiwul4"] = "长戟冲阵，何人能挡？",
}

qiwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#qiwu",
  min_card_num = 1,
  max_card_num = 999,
  target_num = 1,
  can_use = function(self, player)
    if player:usedSkillTimes(qiwu.name, Player.HistoryPhase) == 0 then
      local slash = Fk:cloneCard("slash")
      slash.skillName = qiwu.name
      return player:canUse(slash, { bypass_distances = true, bypass_times = true })
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    if #selected == 0 then
      local slash = Fk:cloneCard("slash")
      slash.skillName = qiwu.name
      return player:canUseTo(slash, to_select, { bypass_distances = true, bypass_times = true })
    end
  end,
  on_use = function(self, room, effect)
    local skillName = qiwu.name
    local player = effect.from
    local target = effect.tos[1]
    local suits = {}
    local c
    local jinks = {}
    for _, id in ipairs(effect.cards) do
      c = Fk:getCardById(id)
      if c.suit ~= Card.NoSuit then
        table.insertIfNeed(suits, c.suit)
      end
      if c.trueName == "jink" then
        table.insertIfNeed(jinks, id)
      end
    end
    room:throwCard(effect.cards, skillName, player, player)
    if not target.dead then
      local slash = Fk:cloneCard("slash")
      slash.skillName = skillName
      room:useCard{
        from = player,
        tos = { target },
        card = slash,
        extraUse = true,
        extra_data = {
          qiwul_data = {
            from = player,
            n = #suits,
            jinks = jinks
          }
        }
      }
    end
  end,
})

qiwu:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiwu.name) and not data.to.dead and
      data.extra_data and data.extra_data.qiwul_data and data.extra_data.qiwul_data.from == player
  end,
  on_use = function(self, event, target, player, data)
    local skillName = qiwu.name
    local room = player.room
    local to = data.to
    local n = data.extra_data.qiwul_data.n
    local jinks = table.simpleClone(data.extra_data.qiwul_data.jinks)
    local cards = room:askToDiscard(to, {
      min_num = n,
      max_num = n,
      skill_name = skillName,
      include_equip = true,
      cancelable = false,
      skip = true
    })
    if #cards == 0 then return end
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).trueName == "jink" then
        table.insertIfNeed(jinks, id)
      end
    end
    room:throwCard(cards, skillName, to, to)
    if #jinks > 0 then
      if not player.dead then
        jinks = table.filter(jinks, function(id)
          return room:getCardArea(id) == Card.DiscardPile and Fk:getCardById(id).trueName == "jink"
        end)
        if #jinks > 0 then
          room:delay(1000)
          room:obtainCard(player, jinks, true, fk.ReasonJustMove, player, skillName, "@@qiwul-inhand-turn")
        end
      end
    else
      data.use.disresponsiveList = table.simpleClone(room.players)
    end
  end,
})

qiwu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@qiwul-inhand-turn") > 0
  end,
})

return qiwu
