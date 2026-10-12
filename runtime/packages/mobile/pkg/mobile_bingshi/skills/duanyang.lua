local duanyang = fk.CreateSkill {
  name = "duanyang",
}

Fk:loadTranslationTable{
  ["duanyang"] = "断鞅",
  [":duanyang"] = "每回合限一次，当你的手牌不因使用而进入弃牌堆后，你可以将其中随机一张【杀】置于你的武将牌上，并于本阶段结束时使用之（无次数限制）。" ..
  "你以此法使用的【杀】造成伤害后，你可以重铸受伤角色区域里的至多两张牌，然后你摸四张牌。",

  ["$duanyang"] = "断鞅",
  ["#duanyang-choose"] = "断鞅：你可重铸 %dest 至多两张区域内的牌",
  ["duanyang_obtain"] = "获得其中基本牌",
  ["duanyang_draw"] = "摸%arg张牌",

  ["$duanyang1"] = "众士向前，退者立斩。",
  ["$duanyang2"] = "大胆竖子，安敢乱我军心。",
  ["$duanyang3"] = "诸将所为甚是得当，吾安可不赏？",
}

duanyang:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(duanyang.name) and player:usedSkillTimes(duanyang.name) == 0) then
      return false
    end

    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if
              info.fromArea == Card.PlayerHand and
              Fk:getCardById(info.cardId).trueName == "slash" and
              room:getCardArea(info.cardId) == Card.DiscardPile
            then
              return true
            end
          end
        else
          local useEvent = room.logic:getCurrentEvent().parent
          local cardIds = {}
          if useEvent ~= nil then
            if useEvent.event == GameEvent.RespondCard then
              local use = useEvent.data
              if use.from == player then
                cardIds = room:getSubcardsByRule(use.card)
              end
            end
          end
          for _, info in ipairs(move.moveInfo) do
            if
              info.fromArea == Card.Processing and
              table.contains(cardIds, info.cardId) and
              Fk:getCardById(info.cardId).trueName == "slash" and
              room:getCardArea(info.cardId) == Card.DiscardPile
            then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local slash = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if
              info.fromArea == Card.PlayerHand and
              Fk:getCardById(info.cardId).trueName == "slash" and
              room:getCardArea(info.cardId) == Card.DiscardPile
            then
              table.insertIfNeed(slash, info.cardId)
            end
          end
        else
          local parentEvent = room.logic:getCurrentEvent().parent
          if parentEvent ~= nil then
            local useEvent = parentEvent.parent
            local cardIds = {}
            if useEvent ~= nil then
              if useEvent.event == GameEvent.RespondCard then
                local use = useEvent.data
                if use.from == player then
                  cardIds = room:getSubcardsByRule(use.card)
                end
              end
            end
            for _, info in ipairs(move.moveInfo) do
              if
                info.fromArea == Card.Processing and
                table.contains(cardIds, info.cardId) and
                Fk:getCardById(info.cardId).trueName == "slash" and
                room:getCardArea(info.cardId) == Card.DiscardPile
              then
                table.insertIfNeed(slash, info.cardId)
              end
            end
          end
        end
      end
    end

    if #slash == 0 then
      return false
    end

    player:addToPile("$duanyang", room:tableRandomPick(slash), true, duanyang.name, player)
  end,
})

duanyang:addEffect(fk.EventPhaseEnd, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$duanyang") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = duanyang.name
    local room = player.room

    local duanyangSlash = player:getPile("$duanyang")
    for _, id in ipairs(duanyangSlash) do
      local use = room:askToUseRealCard(
        player,
        {
          pattern = { id },
          expand_pile = "$duanyang",
          skill_name = skillName,
          extra_data = { bypass_times = true },
          cancelable = false,
          skip = true,
        }
      )

      if use then
        use.extra_data = use.extra_data or {}
        use.extra_data.duanyangUser = player

        room:useCard(use)
      else
        room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, nil, true, player)
      end
    end
  end,
})

duanyang:addEffect(fk.Damage, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and data.card and data.to:isAlive() and not data.to:isAllNude()) then
      return false
    end

    local effect = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    return effect and (effect.data.extra_data or {}).duanyangUser == player
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = duanyang.name
    local room = player.room

    local ids = room:askToChooseCards(
      player,
      {
        min = 0,
        max = 2,
        flag = "hej",
        target = data.to,
        skill_name = skillName,
        prompt = "#duanyang-choose::" .. data.to.id,
      }
    )

    if #ids == 0 then
      return false
    end
    room:recastCard(ids, data.to, skillName)

    if not player:isAlive() then
      return false
    end
    player:drawCards(4, skillName)
  end,
})

return duanyang
