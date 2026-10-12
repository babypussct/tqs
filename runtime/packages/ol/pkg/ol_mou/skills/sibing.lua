local sibing = fk.CreateSkill {
  name = "sibing",
}

Fk:loadTranslationTable{
  ["sibing"] = "司兵",
  [":sibing"] = "每回合限一次，当你使用伤害牌指定唯一目标时，你可以弃置任意张红色牌，目标需弃置等量红色手牌，否则其不能响应此牌；"..
    "以你为目标的伤害牌结算完成后，若未对你造成伤害，你可以弃置一张黑色牌，视为使用一张【杀】。",

  ["#sibing1-invoke"] = "司兵：你可以弃置任意张红色牌，令 %dest 需弃置等量红色手牌，否则其不能响应此牌",
  ["#sibing-discard"] = "司兵：你需弃置%arg张红色手牌，否则不能响应此%arg2",
  ["#sibing2-invoke"] = "司兵：你可以弃置一张黑色牌，视为使用一张【杀】",

  ["$sibing1"] = "钲鼓鸣，山河动，老夫定为天子荡平逆乱。",
  ["$sibing2"] = "筑围凿堑，合而不攻，待以时日贼自生变。",
}

sibing:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(sibing.name) and not data.cancelled and
      data.card.is_damage_card and not data.to.dead and data:isOnlyTarget(data.to) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = sibing.name,
      pattern = ".|.|heart,diamond",
      prompt = "#sibing1-invoke::"..data.to.id,
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {data.to}, cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #event:getCostData(self).cards
    room:throwCard(event:getCostData(self).cards, sibing.name, player, player)
    if data.to.dead then return end
    if #room:askToDiscard(data.to, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = sibing.name,
      pattern = ".|.|heart,diamond",
      prompt = "#sibing-discard:::"..n..":"..data.card:toLogString(),
      cancelable = true,
    }) == 0 then
      data.use.disresponsiveList = data.use.disresponsiveList or {}
      table.insertIfNeed(data.use.disresponsiveList, data.to)
    end
  end,
})

sibing:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(sibing.name) and table.contains(data.tos, player) and
      data.card.is_damage_card and not (data.damageDealt and data.damageDealt[player]) and
      not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local slash = Fk:cloneCard("slash")
      slash.skillName = sibing.name
      return not not table.find(player.room.alive_players, function(p)
        return player:canUseTo(slash, p, { bypass_times = true })
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    slash.skillName = sibing.name
    local targets = table.filter(room.alive_players, function(p)
      return player:canUseTo(slash, p, { bypass_times = true })
    end)
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      pattern = ".|.|spade,club",
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = sibing.name,
      prompt = "#sibing2-invoke",
      cancelable = true,
      will_throw = true,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, { tos = to, cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, sibing.name, player, player)
    local to = event:getCostData(self).tos[1]
    if not to.dead then
      room:useVirtualCard("slash", nil, player, to, sibing.name, true)
    end
  end,
})

return sibing
