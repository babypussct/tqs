
local chengwang = fk.CreateSkill{
  name = "chengwang",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["chengwang"] = "承望",
  [":chengwang"] = "转换技，每轮你首次使用一个花色的牌后，若体力值大于等于0，你可以对自己造成1点伤害，"..
  "阳：从弃牌堆中获得X张花色不同的牌；阴：重铸至多X张与此牌花色相同的牌（X为你已损失体力值+1）。"..
  "若你因此手牌数变为全场最多或最少，你可以令一名角色回复1点体力。",

  ["@chengwang-round"] = "承望",
  ["#chengwang-yang"] = "承望：你可以对自己造成1点伤害，从弃牌堆获得已损失体力值+1张不同花色的牌",
  ["#chengwang-yin"] = "承望：你可以对自己造成1点伤害，重铸至多已损失体力值+1张相同花色的牌",
  ["#chengwang-recast"] = "承望：你可以重铸至多%arg张%arg2牌",
  ["#chengwang-choose"] = "承望：你可以令一名角色回复1点体力",

  ["$chengwang1"] = "",
  ["$chengwang2"] = "",
}

chengwang:addEffect(fk.CardUseFinished, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chengwang.name) and player.hp >= 0 then
      local suit = data.card.suit
      if suit == Card.NoSuit then return false end
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent()
      local mark_name = "chengwang_" .. data.card:getSuitString() .. "-round"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data
          if last_use.from == player and last_use.card.suit == suit then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryRound)
      end
      return mark == use_event.id
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengwang.name,
      prompt = "#chengwang-"..player:getSwitchSkillState(chengwang.name, false, true),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = chengwang.name,
    }
    if player.dead then return end
    local n = player:getLostHp() + 1
    if player:currentSwitchState() == fk.SwitchYang then
      local mapper = {}
      for _, id in ipairs(room.discard_pile) do
        local suit = Fk:getCardById(id):getSuitString()
        mapper[suit] = mapper[suit] or {}
        table.insert(mapper[suit], id)
      end
      local suits = {}
      for k, _ in pairs(mapper) do
        table.insert(suits, k)
      end
      suits = room:tableRandomPick(suits, n)
      local cards = {}
      for k, ids in pairs(mapper) do
        if table.contains(suits, k) then
          table.insert(cards, room:tableRandomPick(ids))
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, chengwang.name, nil, false, player)
        if player.dead then return end
      else
        return
      end
    elseif not player:isNude() then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = n,
        skill_name = chengwang.name,
        pattern = ".|.|"..data.card:getSuitString(),
        prompt = "#chengwang-recast:::"..n..":"..data.card:getSuitString(true),
        cancelable = true,
      })
      if #cards > 0 then
        room:recastCard(cards, player, chengwang.name)
        if player.dead then return end
      else
        return
      end
    end
    if table.every(room.alive_players, function (p)
      return player:getHandcardNum() >= p:getHandcardNum()
    end) or
    table.every(room.alive_players, function (p)
      return player:getHandcardNum() <= p:getHandcardNum()
    end) then
      local targets = table.filter(room.alive_players, function (p)
        return p:isWounded()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          skill_name = chengwang.name,
          cancelable = true,
          prompt = "#chengwang-choose",
        })
        if #to > 0 then
          room:recover{
            who = to[1],
            num = 1,
            recoverBy = player,
            skillName = chengwang.name,
          }
        end
      end
    end
  end,
})

chengwang:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengwang.name, true) and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@chengwang-round", data.card:getSuitString(true))
  end,
})

chengwang:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local suits = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(suits, use.card:getSuitString(true))
      end
    end, Player.HistoryRound)
    table.removeOne(suits, "log_nosuit")
    if #suits > 0 then
      room:setPlayerMark(player, "@chengwang-round", suits)
    end
  end
end)
chengwang:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@chengwang-round", 0)
end)

return chengwang
