local fengshang = fk.CreateSkill{
  name = "fengshang",
}

Fk:loadTranslationTable{
  ["fengshang"] = "封赏",
  [":fengshang"] = "出牌阶段限一次，或有角色进入濒死状态时（每回合限一次），你可以将本回合弃牌堆中两张花色相同的牌分配给等量角色"..
  "（每轮每种花色限一次），若你未以此法获得牌，你视为使用一张不计入次数的【酒】。",

  ["#fengshang"] = "封赏：你可以将本回合弃牌堆中两张花色相同的牌分配给等量角色",
  ["#fengshang-choose"] = "封赏：分配其中两张花色相同的牌",
  ["@[fengshang]"] = "封赏",

  ["$fengshang1"] = "干了这杯酒，你便是老夫生死弟兄！",
  ["$fengshang2"] = "来来来！金杯共汝饮，荣华共汝享！",
}

---@param player Player
---@return integer[]
local getFengshangCards = function(player)
  local suits = player:getTableMark("fengshang-round")
  if #suits == 4 then return {} end
  local cards = player:getTableMark("fengshang-turn")
  if #cards == 0 then return {} end
  local cardmap = {{}, {}, {}, {}}
  local room = Fk:currentRoom()
  local suit
  for _, id in ipairs(cards) do
    if room:getCardArea(id) == Card.DiscardPile then
      suit = Fk:getCardById(id, true).suit
      if suit ~= Card.NoSuit and not table.contains(suits, suit) then
        table.insert(cardmap[suit], id)
      end
    end
  end
  cards = {}
  for _, value in ipairs(cardmap) do
    if #value> 1 then
      table.insertTable(cards, value)
    end
  end
  return cards
end

fengshang:addEffect("active", {
  anim_type = "support",
  prompt = "#fengshang",
  card_num = 0,
  target_num = 0,
  expand_pile = function(self, player)
    return player:getTableMark("fengshang")
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(fengshang.name, Player.HistoryPhase) == 0 and #getFengshangCards(player) > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = getFengshangCards(player)
    if #cards < 2 then return end

    local targets = table.map(room.alive_players, Util.IdMapper)
    local toStr = function(int) return string.format("%d", int) end
    local residueMap = {}
    for _, id in ipairs(targets) do
      residueMap[toStr(id)] = 1
    end
    local data = {
      cards = cards,
      max_num = 1,
      targets = targets,
      residued_list = residueMap,
      expand_pile = cards,
    }

    local list = {}
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "distribution_select_skill",
      prompt = "#fengshang-choose",
      cancelable = false,
      extra_data = data,
      no_indicate = false,
      skip = true,
    })
    if success and dat then
      table.removeOne(targets, dat.targets[1].id)
      list[dat.targets[1].id] = dat.cards
      room:setCardMark(Fk:getCardById(dat.cards[1]), "@DistributionTo", Fk:translate(dat.targets[1].general))
      room:addTableMark(player, "fengshang-round", Fk:getCardById(dat.cards[1]).suit)
    else
      return
    end
    if #targets > 0 then
      local all_cards = table.filter(cards, function (c)
        return Fk:getCardById(c):compareSuitWith(Fk:getCardById(dat.cards[1]))
      end)
      cards = table.simpleClone(all_cards)
      table.removeOne(cards, dat.cards[1])
      data = {
        cards = cards,
        max_num = 1,
        targets = targets,
        residued_list = residueMap,
        expand_pile = all_cards,
      }
      success, dat = room:askToUseActiveSkill(player, {
        skill_name = "distribution_select_skill",
        prompt = "#fengshang-choose",
        cancelable = false,
        extra_data = data,
        no_indicate = false,
        skip = true,
      })
      if success and dat then
        list[dat.targets[1].id] = dat.cards
      end
    end
    for _, ids in pairs(list) do
      for _, id in ipairs(ids) do
        room:setCardMark(Fk:getCardById(id), "@DistributionTo", 0)
      end
    end
    room:doYiji(list, player, fengshang.name)
    if not player.dead and not list[player.id] then
      local card = Fk:cloneCard("analeptic")
      card.skillName = fengshang.name
      if player:canUseTo(Fk:cloneCard("analeptic"), player, {bypass_times = true}) then
        room:useCard({
          card = card,
          from = player,
          tos = {player},
          extra_data = {
            analepticRecover = player.dying
          },
          extraUse = true,
        })
      end
    end
  end,
})

fengshang:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengshang.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      #getFengshangCards(player) > 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fengshang.name,
      prompt = "#fengshang",
    })
  end,
  on_use = function(self, event, target, player, data)
    Fk.skills[fengshang.name]:onUse(player.room, {
      from = player,
      cards = {},
      tos = {},
    })
  end,
})

fengshang:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(fengshang.name, true) and player.room:getCurrent()
  end,
  on_refresh = function (self, event, target, player, data)
    local cards = player:getTableMark("fengshang-turn")
    local n = #cards
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
    if #cards > n then
      player.room:setPlayerMark(player, "fengshang-turn", cards)
    end
  end
})

fengshang:addAcquireEffect(function (self, player)
  local room = player.room
  room:setPlayerMark(player, "@[fengshang]", 1)
  local cards = {}
  room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
    for _, move in ipairs(e.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
        end
      end
    end
  end, nil, Player.HistoryTurn)
  if #cards > 0 then
    room:setPlayerMark(player, "fengshang-turn", cards)
  end
end)

fengshang:addLoseEffect(function (self, player)
  local room = player.room
  room:setPlayerMark(player, "@[fengshang]", 0)
  room:setPlayerMark(player, "fengshang-round", 0)
end)

Fk:addQmlMark{
  name = "fengshang",
  how_to_show = function(name, value, p)
    local mark = p:getTableMark("fengshang-round")
    if #mark > 0 then
      return table.concat(table.map(mark, function(suit)
        return Fk:translate(Card.getSuitString({ suit = suit }, true))
      end), "")
    end
    return " "
  end,
  qml = function(name, value, p)
    return {
      uri = "LunarLtk.Pages.InfoPopups",
      name = "ViewPile",
      prop = {
        ids = getFengshangCards(p)
      },
    }
  end,
}

return fengshang
