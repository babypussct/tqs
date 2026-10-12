local qianxiong = fk.CreateSkill{
  name = "os__qianxiong",
}

Fk:loadTranslationTable{
  ["os__qianxiong"] = "潜凶",
  [":os__qianxiong"] = "①出牌阶段限一次，你可以观看牌堆顶五张牌，将其中一张牌扣置于一名角色的武将牌上。②有“潜凶”牌的角色出牌阶段开始时，"..
    "你选择一项：1.本回合当其使用或打出与“潜凶”牌相同牌名的牌时，你对其造成1点伤害，本回合结束时将与其本回合使用或打出过的相同牌名的“潜凶”牌置入弃牌堆；"..
    "2.你依次使用其所有“潜凶”牌。",

  ["#os__qianxiong-put"] = "潜凶：观看牌堆顶五张牌，选择一张牌，扣置于一名角色的武将牌上",
  ["os__qianxiong_dmg"] = "本回合当%dest使用或打出与“潜凶”牌相同牌名的牌时，你对其造成1点伤害，<br/>本回合结束时将与其本回合使用或打出过的相同牌名的“潜凶”牌置入弃牌堆",
  ["os__qianxiong_use"] = "你依次使用%dest所有“潜凶”牌",
  ["@@os__qianxiong_dmg-turn"] = "潜凶 伤害",
  ["#os__qianxiong-use"] = "潜凶：依次使用%dest所有“潜凶”牌",

  ["$os__qianxiong1"] = "暗伏甲士，待机而行！",
  ["$os__qianxiong2"] = "明既不能取胜，不妨以暗箭诛之！",
}

qianxiong:addEffect("active", {
  anim_type = "control",
  can_use = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  on_use = function (self, room, effect)
    local player = effect.from
    local cids = room:getNCards(5)
    local tars, cards = room:askToChooseCardsAndPlayers(player, {
      expand_pile = cids,
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = self.name,
      prompt = "#os__qianxiong-put",
      cancelable = false,
      pattern = tostring(Exppattern{ id = cids }),
    })
    tars[1]:addToPile(qianxiong.name, cards, false, qianxiong.name, player, player) -- 多个潜凶直接共用了，偷懒
  end
})

qianxiong:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return #target:getPile(qianxiong.name) > 0 and target.phase == Player.Play and player:hasSkill(self.name)
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"os__qianxiong_dmg::" .. target.id, "os__qianxiong_use::" .. target.id},
      skill_name = self.name
    })
    event:setCostData(self, {tos = {target}, choice = choice})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("os__qianxiong_dmg") then
      room:addTableMark(target, "@@os__qianxiong_dmg-turn", player.id)
    else
      for _, c in ipairs(target:getPile("os__qianxiong")) do
        if player.dead then return end
        room:askToUseRealCard(player, {
          pattern = {c},
          skill_name = self.name,
          prompt = "#os__qianxiong-use::" .. target.id,
          extra_data = {
            bypass_times = true,
            extraUse = true,
            expand_pile = {c},
          },
        })
      end
    end
  end
})

qianxiong:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return #target:getPile("os__qianxiong") > 0 and
      table.contains(target:getTableMark("@@os__qianxiong_dmg-turn"), player.id) and
      table.contains(table.map(target:getPile("os__qianxiong"), function(id)
        return Fk:getCardById(id).name
      end), data.card.name)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {target} })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(target, "_os__qianxiong_dmged", data.card.trueName)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = qianxiong.name,
    }
  end
})

qianxiong:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("_os__qianxiong_dmged") ~= 0 and
      #player:getPile("os__qianxiong") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getPile("os__qianxiong"), function(id) return
      table.contains(player:getMark("_os__qianxiong_dmged"), Fk:getCardById(id).trueName)
    end)
    room:setPlayerMark(player, "_os__qianxiong_dmged", 0)
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, qianxiong.name, true, player)
  end
})

qianxiong:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function(p)
    return not p:hasSkill(qianxiong.name, true)
  end) then
    table.forEach(room:getAlivePlayers(), function(p)
      if #p:getPile(qianxiong.name) > 0 then
        room:moveCardTo(p:getPile(qianxiong.name), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile)
      end
    end)
  end
end)

return qianxiong
