local zengou = fk.CreateSkill {
  name = "os__zengou",
}

Fk:loadTranslationTable{
  ["os__zengou"] = "谮构",
  [":os__zengou"] = "出牌阶段限一次，你可以观看一名角色的所有手牌，然后选择一项：<br>"..
  "1.视为使用两张其手牌中没有的牌名的基本牌（不计入次数且无次数限制）；<br>"..
  "2.你与其依次将手牌区里的共有牌名的牌替换为牌堆中等量的【杀】（以此法得到的【杀】不计入手牌上限，直到各自的回合结束）。<br>"..
  "然后其获得一个你指定基本牌名的“诬”标记。拥有此标记的角色每回合使用的前三张牌结算后，若与记录的牌名相同，其移除此标记并失去1点体力。",

  ["#os__zengou"] = "谮构：观看一名角色手牌并选择一项",
  ["#os__zengou-choose"] = "谮构：观看%dest的手牌并选择一项",
  ["os__zengou_use"] = "视为使用基本牌",
  ["os__zengou_exchange"] = "将牌替换为【杀】",
  ["#os__zengou-use"] = "谮构：你可以依次使用不同牌名的基本牌各一张（不计入次数且无次数限制）",
  ["#os__zengou-bname"] = "谮构：为%dest的“诬”标记记录一种基本牌的名称",
  ["@os__zengou-round"] = "谮构",

  ["@@os__zengou-inhand"] = "谮构",
  ["@[private]os__zengou_wu"] = "诬",

  ["$os__zengou1"] = "哼，待此书上达天听，你必死无疑。",
  ["$os__zengou2"] = "身囚狱中，滋味如何啊。",
  ["$os__zengou3"] = "夏侯楙，我想要治你，有的是手段。",
}

local U = require "packages.utility.utility"

local shuffleCardtoDrawPile = function (player, cards, skillName, proposer)
  proposer = proposer or player
  local room = player.room
  local x = #cards
  table.shuffle(cards)
  local positions = {}
  local y = #room.draw_pile
  for _ = 1, x, 1 do
    table.insert(positions, math.random(y+1))
  end
  table.sort(positions, function (a, b)
    return a > b
  end)
  local moveInfos = {}
  for i = 1, x, 1 do
    table.insert(moveInfos, {
      ids = {cards[i]},
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      drawPilePosition = positions[i],
      proposer = proposer,
    })
  end
  room:moveCards(table.unpack(moveInfos))
end

zengou:addEffect("active", {
  anim_type = "control",
  prompt = "#os__zengou",
  mute = true,
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng() and
      not table.contains(player:getTableMark("os__zengou_prohibit"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:notifySkillInvoked(player, zengou.name, "control", effect.tos)
    player:broadcastSkillInvoke(zengou.name, math.random(2))
    local cids = target:getCardIds("h")
    local choice = room:askToViewCardsAndChoice(player, {
      cards = cids,
      choices = {"os__zengou_use", "os__zengou_exchange"},
      skill_name = zengou.name,
      prompt = "#os__zengou-choose::" .. target.id
    })
    local card
    local cardName
    local names = {}
    table.forEach(cids, function(id)
      names[Fk:getCardById(id).trueName] = true
    end)
    if choice == "os__zengou_use" then
      local cards = Fk:getAllCardNames("b", true)
      local toUse = table.filter(cards, function(name)
        return not names[name]
      end)
      for _ = 1, 2 do
        if #cards == 0 then break end
        local use = room:askToUseVirtualCard(player, {
          name = toUse,
          skill_name = zengou.name,
          prompt = "#os__zengou-use",
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
          cancelable = false,
        })
        if use then
          room:addPlayerMark(player, "@os__zengou-round")
          table.removeOne(toUse, use.card.trueName)
        else
          break
        end
      end
    else
      local cardMap = {}
      for _, id in ipairs(player:getCardIds("h")) do
        card = Fk:getCardById(id)
        cardName = card.trueName
        cardMap[cardName] = cardMap[cardName] or {}
        table.insert(cardMap[cardName], id)
      end
      local toPut = {}
      local cardNames = {}
      for _, id in ipairs(cids) do
        card = Fk:getCardById(id)
        cardName = card.trueName
        if cardMap[cardName] then
          table.insert(cardNames, cardName)
          table.insertTable(toPut, cardMap[cardName])
          cardMap[cardName] = nil
        end
      end
      local x = #toPut
      if x > 0 then
        shuffleCardtoDrawPile(player, toPut, zengou.name)
        if not player.dead then
          toPut = room:getCardsFromPileByRule("slash", x)
          if #toPut > 0 then
            room:obtainCard(player, toPut, false, fk.ReasonJustMove, player, zengou.name, "@@os__zengou-inhand")
          end
        end
        toPut = table.filter(target:getCardIds("h"), function (id)
          return table.contains(cardNames, Fk:getCardById(id).trueName)
        end)
        x = #toPut
        if x > 0 then
          shuffleCardtoDrawPile(target, toPut, zengou.name, player)
          if not target.dead then
            toPut = room:getCardsFromPileByRule("slash", x)
            if #toPut > 0 then
              room:obtainCard(target, toPut, false, fk.ReasonJustMove, player, zengou.name, "@@os__zengou-inhand")
            end
          end
        end
      end
    end
    if player:hasSkill(zengou.name, true) and not target.dead then
      local cards = room:getUniversalCards("b", true)
      local wuMark = target:getMark("@[private]os__zengou_wu")
      if type(wuMark) == "table" and type(wuMark.value) == "table" then
        cards = table.filter(cards, function(id)
          return not table.contains(wuMark.value, Fk:getCardById(id).trueName)
        end)
      end
      if #cards > 0 then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = {
            card_data = {
              { "basic", cards }
            }
          },
          skill_name = zengou.name,
          prompt = "#os__zengou-bname::" .. target.id
        })

        local trueName = Fk:getCardById(id).trueName
        local bindMark = target:getTableMark("os__zengou_bind")
        if bindMark[trueName] == player.id then
          return false
        end

        local value, players
        if wuMark == 0 then
          value = { trueName }
          players = { player.id }
        else
          table.insertIfNeed(wuMark.value, trueName)
          table.insertIfNeed(wuMark.players, player.id)
          value = wuMark.value
          players = wuMark.players
        end

        U.setPrivateMark(target, "os__zengou_wu", value, players)

        bindMark[trueName] = player.id
        room:setPlayerMark(target, "os__zengou_bind", bindMark)
      end
    end
  end,
})

zengou:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= data.from or not table.contains(U.getPrivateMark(player, "os__zengou_wu"), data.card.trueName) then
      return false
    end

    local room = player.room
    local zengouBind = player:getTableMark("os__zengou_bind")
    if next(zengouBind) == nil or not room:getPlayerById(zengouBind[data.card.trueName]):hasSkill(zengou.name) then
      return false
    end

    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark = player:getMark("os__zengou-turn")
    if mark < 3 then
      room:setPlayerMark(player, "os__zengou-turn", 0)
      logic:getEventsOfScope(GameEvent.UseCard, 3, function (e)
        local last_use = e.data
        if last_use.from == player then
          mark = e.id
          room:addPlayerMark(player, "os__zengou-turn", 1)
          return true
        end
      end, Player.HistoryTurn)
    end
    return mark == use_event.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zengou.name, "negative")
    player:broadcastSkillInvoke(zengou.name, 3)

    local trueName = data.card.trueName
    local bindMark = target:getTableMark("os__zengou_bind")
    local removeCurrentPlayer = bindMark[trueName]
    bindMark[trueName] = nil
    for _, playerId in pairs(bindMark) do
      if playerId == removeCurrentPlayer then
        removeCurrentPlayer = nil
        break
      end
    end
    if next(bindMark) == nil then
      room:setPlayerMark(player, "os__zengou_bind", 0)
    else
      room:setPlayerMark(player, "os__zengou_bind", bindMark)
    end

    local wuMark = U.getPrivateMark(player, "os__zengou_wu")
    table.removeOne(wuMark, trueName)
    if #wuMark == 0 then
      room:setPlayerMark(player, "@[private]os__zengou_wu", 0)
    else
      local visiblePlayers = player:getMark("@[private]os__zengou_wu").players
      if removeCurrentPlayer then
        table.removeOne(visiblePlayers, removeCurrentPlayer)
      end
      U.setPrivateMark(player, "os__zengou_wu", wuMark, visiblePlayers)
    end

    room:loseHp(player, 1, zengou.name)
  end,
})

zengou:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@os__zengou-inhand") > 0
  end,
})

zengou:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:clearHandMark(player, "@@os__zengou-inhand")
  end,
})

zengou:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "@os__zengou-round", 0)
  room:setPlayerMark(player, "os__zengou_prohibit", 0)
  for _, p in ipairs(room.alive_players) do
    if p:getMark("os__zengou_bind") ~= 0 then
      local wuMark = p:getTableMark("@[private]os__zengou_wu")
      local bindMark = p:getTableMark("os__zengou_bind")
      for trueName, playerId in pairs(p:getTableMark("os__zengou_bind")) do
        if playerId == player.id then
          bindMark[trueName] = nil
          table.removeOne(wuMark.value or {}, trueName)
        end
      end

      if #(wuMark.value or {}) == 0 then
        room:setPlayerMark(p, "@[private]os__zengou_wu", 0)
      else
        table.removeOne(wuMark.players or {}, player.id)
        U.setPrivateMark(player, "os__zengou_wu", wuMark.value, wuMark.players)
      end

      if next(bindMark) == nil then
        room:setPlayerMark(p, "os__zengou_bind", 0)
      else
        room:setPlayerMark(p, "os__zengou_bind", bindMark)
      end
    end
  end
end)

return zengou
