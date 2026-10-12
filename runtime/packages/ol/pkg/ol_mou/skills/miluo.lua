local miluo = fk.CreateSkill {
  name = "miluo",
}

Fk:loadTranslationTable{
  ["miluo"] = "迷落",
  [":miluo"] = "出牌阶段限一次，你可以展示并交给至多两名其他角色各一张牌，这些牌本轮称为“迷落”牌。每轮结束时，你可以令其中一名手牌中"..
  "没有“迷落”牌的角色失去1点体力，或令其中一名手牌中有“迷落”牌的角色回复1点体力。",

  ["#miluo"] = "迷落：展示并交给至多两名其他角色各一张牌",
  ["#miluo-give"] = "迷落：将这些牌交给其他角色",
  ["@@miluo-inhand-round"] = "迷落",
  ["#miluo-choose"] = "迷落：你可以令其中一名角色失去或回复1点体力",

  ["$miluo1"] = "闻清芬以醉月，赏红颜而迷花。",
  ["$miluo2"] = "仙姑撷花迷魂魄，娘子折枝落死生。",
}

miluo:addEffect("active", {
  anim_type = "control",
  prompt = "#miluo",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(miluo.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected < math.min(2, #table.filter(Fk:currentRoom().alive_players, function(p) return p ~= player end))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player.dead then return end
    local cards = table.filter(effect.cards, function (id)
      return table.contains(player:getCardIds("he"), id)
    end)
    if #cards == 0 or #player.room:getOtherPlayers(player, false) == 0 then return end
    local n = math.min(#cards, #player.room:getOtherPlayers(player, false))
    local result = room:askToYiji(player, {
      cards = cards,
      targets = room:getOtherPlayers(player, false),
      skill_name = miluo.name,
      min_num = n,
      max_num = n,
      prompt = "#miluo-give",
      single_max = 1,
      cancelable = false,
      skip = true,
    })

    player:showCards(effect.cards)
    room:delay(1000)
    for id, ids in pairs(result) do
      if #ids > 0 then
        room:addTableMarkIfNeed(player, "miluo-round", id)
      end
    end
    room:doYiji(result, player, miluo.name, "@@miluo-inhand-round")
  end,
})

Fk:addTargetTip{
  name = "miluo",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    if not table.find(to_select:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@miluo-inhand-round") > 0
    end) then
      return "lose_hp"
    elseif to_select:isWounded() then
      return "heal_hp"
    end
  end,
}

miluo:addEffect(fk.RoundEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(miluo.name) and player:getMark("miluo-round") ~= 0 then
      for _, id in ipairs(player:getTableMark("miluo-round")) do
        local p = player.room:getPlayerById(id)
        if not p.dead then
          if not table.find(p:getCardIds("h"), function (c)
            return Fk:getCardById(c):getMark("@@miluo-inhand-round") > 0
          end) then
            return true
          elseif p:isWounded() then
            return true
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, id in ipairs(player:getTableMark("miluo-round")) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if not table.find(p:getCardIds("h"), function (c)
          return Fk:getCardById(c):getMark("@@miluo-inhand-round") > 0
        end) then
          table.insert(targets, p)
        elseif p:isWounded() then
          table.insert(targets, p)
        end
      end
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = miluo.name,
      prompt = "#miluo-choose",
      cancelable = true,
      target_tip_name = miluo.name,
    })
    if #to > 0 then
      local choice = "recover"
      if not table.find(to[1]:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@miluo-inhand-round") > 0
      end) then
        choice = "loseHp"
      end
      event:setCostData(self, {tos = to, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "loseHp" then
      room:loseHp(to, 1, miluo.name)
    else
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = miluo.name,
      }
    end
  end,
})

return miluo
