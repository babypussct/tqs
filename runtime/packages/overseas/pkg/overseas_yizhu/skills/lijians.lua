local osLijians = fk.CreateSkill {
  name = "os__lijians",
  tags = { Skill.Spirited },
}

Fk:loadTranslationTable{
  ["os__lijians"] = "力谏",
  [":os__lijians"] = "<a href='#SpiritedSkillDesc'>昂扬技</a>，其他角色的弃牌阶段结束时，你可获得任意张此回合因弃置而移至弃牌堆里的牌，" ..
      "然后将其余牌交给其，若其获得的牌数大于等于你，则你对其造成1点伤害。<a href='#SpiritedSkillDesc'>激昂</a>：X张牌因弃置而进入弃牌堆。（X为游戏角色数）",

  ["@os__lijians"] = "力谏",
  ["#os__lijians-invoke"] = "力谏：你可获得任意张此回合因弃置而移至弃牌堆里的牌，然后将其余牌交给 %dest（可点标记预览）",
  ["os__lijians_all_get"] = "获得所有牌",
  ["os__lijians_get"] = "获得选中牌，其余交还",
  ["os__lijians_back"] = "交还选中牌，其余获得",
  ["#os__lijian-cards"] = "力谏：你可获得任意张此回合因弃置而移至弃牌堆里的牌，将其余牌交给%dest",
  ["os__lijians_all_back"] = "交还所有牌",
  ["#os__lijian-card"] = "力谏：你可获得此牌或交给 %dest",
  ["@$os__lijians_temp_cards"] = "力谏牌",

  ["$os__lijians1"] = "陛下欲复昔日桓公之事乎？",
  ["$os__lijians2"] = "君者当御贤于后，安可校勇于猛兽！",
}

osLijians:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if
      not player:hasSkill(osLijians.name) or
      target.phase ~= Player.Discard or
      target == player or player:getMark("@os__lijians") ~= 0
    then
      return false
    end

    local room = player.room
    return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
      return false
    end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.DiscardPile then
              table.insertIfNeed(cards, id)
            end
          end
        end
      end
      return false
    end, Player.HistoryTurn)
    if #cards == 0 then
      return false
    end

    room:setPlayerMark(player, "@$os__lijians_temp_cards", cards)
    local prompt = "#os__lijians-invoke::" .. target.id
    if room:askToSkillInvoke(player, { skill_name = osLijians.name, prompt = prompt }) then
      room:setPlayerMark(player, "@$os__lijians_temp_cards", 0)
      event:setCostData(self, { extra_data = cards, tos = { target } })
      return true
    end
    room:setPlayerMark(player, "@$os__lijians_temp_cards", 0)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osLijians.name
    local room = player.room
    local cards = event:getCostData(self).extra_data
    room:setPlayerMark(player, "@os__lijians", #room.players)
    local to_get, cids, to_back = {}, {}, {}
    local choice = "os__lijians_all_get"
    if #cards > 1 then
      cids, choice = room:askToChooseCardsAndChoice(player, {
        cards = cards,
        choices = { "os__lijians_get", "os__lijians_back" },
        skill_name = skillName,
        prompt = "#os__lijian-cards::" .. target.id,
        cancel_choices = { "os__lijians_all_get", "os__lijians_all_back" },
        min_num = 0,
        max_num = #cards
      })
    else
      choice = room:askToViewCardsAndChoice(player, {
        cards = cards,
        choices = { "os__lijians_all_get", "os__lijians_all_back" },
        skill_name = skillName,
        prompt = "#os__lijian-card::" .. target.id
      })
    end
    if choice == "os__lijians_all_get" then
      to_get = cards
    elseif choice == "os__lijians_back" then
      to_back = cids
      local tmp = table.simpleClone(cards)
      for _, c in ipairs(cids) do
        table.removeOne(tmp, c)
      end
      to_get = tmp
    elseif choice == "os__lijians_all_back" then
      to_back = cards
    elseif choice == "os__lijians_get" then
      to_get = cids
      local tmp = table.simpleClone(cards)
      for _, c in ipairs(cids) do
        table.removeOne(tmp, c)
      end
      to_back = tmp
    end
    if #to_get > 0 then
      room:obtainCard(player, to_get, true, fk.ReasonJustMove, player, skillName)
    end
    if #to_back > 0 and target:isAlive() then
      room:moveCardTo(to_back, Card.PlayerHand, target, fk.ReasonGive, skillName, nil, true, player)
    end
    if not (target:isAlive() and player:isAlive()) then
      return false
    end

    if #to_back >= #to_get then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

osLijians:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(osLijians.name) and
      player:getMark("@os__lijians") > 0 and
      table.find(data, function(move) return move.toArea == Card.DiscardPile end)
  end,
  on_refresh = function(self, event, target, player, data)
    local num = player:getMark("@os__lijians")
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        num = num - #move.moveInfo
      end
    end
    player.room:setPlayerMark(player, "@os__lijians", math.max(num, 0))
  end,
})

osLijians:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@os__lijians", 0)
end)

return osLijians
