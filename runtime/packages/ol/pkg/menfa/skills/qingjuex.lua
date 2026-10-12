local qingjuex = fk.CreateSkill{
  name = "qingjuex",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingjuex"] = "清绝",
  [":qingjuex"] = "锁定技，你手牌中每个花色仅一张的牌，不计入手牌上限。"..
    "当你每回合体力值首次变化后，你弃置手牌中任意张花色数量不为一的牌，并执行以下等量项：<br>"..
    "1.将这些牌交给一名其他角色；<br>2.获得手牌中未拥有花色的牌各一张。",

  ["#qingjuex-discard"] = "清绝：弃置任意张有重复花色的手牌，执行等量项",
  ["#qingjuex-give"] = "清绝：是否将这些牌交给一名其他角色？",
  ["#qingjuex-prey"] = "清绝：是否获得手牌中未拥有花色的牌各一张？",
  ["qingjuex_give"] = "将弃牌交给一名其他角色",
  ["qingjuex_draw"] = "获得手牌中未拥有花色的牌各一张",

  ["$qingjuex1"] = "节草长于绝涯，唯得清寒而自立。",
  ["$qingjuex2"] = "芷兰生深林，非以无人而不芳。",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qingjuex.name) then
      local room = player.room
      local g_event = room.logic:getCurrentEvent()
      local x = player:getMark("ol__qingjuex_record-turn")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
          if e.data.who == player then
            x = e.id
            room:setPlayerMark(player, "ol__qingjuex_record-turn", x)
            return true
          end
        end, Player.HistoryTurn)
      end
      if x == 0 or x < g_event.id then return end
      return room.logic.all_game_events[x].parent == g_event
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    local suitCount = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id):getSuitString()
      if suit ~= "nosuit" then
        suitCount[suit] = (suitCount[suit] or 0) + 1
      end
    end
    local suits = {}
    for suit, count in pairs(suitCount) do
      if count == 1 then
        table.insert(suits, suit)
      end
    end
    local pattern = "."
    if #suits > 0 then
      pattern = ".|.|^(" .. table.concat(suits, ",") .. ")"
    end
    cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = qingjuex.name,
      pattern = pattern,
      prompt = "#qingjuex-discard",
      cancelable = false,
    })
    local n = #cards
    if n == 0 or player.dead then return end

    local choices = {}
    local targets = room:getOtherPlayers(player, false)
    if #targets > 0 then
      choices = { "qingjuex_give" }
    end

    suits = {1, 2, 3, 4}
    for _, id in ipairs(player:getCardIds("h")) do
      table.removeOne(suits, Fk:getCardById(id).suit)
    end
    if #suits > 0 then
      table.insert(choices, "qingjuex_draw")
    end

    if #choices == 0 then
      return
    elseif #choices > n then
      choices = {
        room:askToChoice(player, {
          choices = choices,
          all_choices = {"qingjuex_give", "qingjuex_draw"},
          skill_name = qingjuex.name,
        })
      }
    end

    if table.contains(choices, "qingjuex_give") then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#qingjuex-give",
        skill_name = qingjuex.name,
        cancelable = false,
      })

      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.DiscardPile end)
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, to[1], fk.ReasonGive, qingjuex.name, nil, true, player)
      end

      if player.dead or #choices == 1 then return end
      suits = {1, 2, 3, 4}
      for _, id in ipairs(player:getCardIds("h")) do
        table.removeOne(suits, Fk:getCardById(id).suit)
      end
      if #suits == 0 then return end
    end

    cards = {}
    local drawPile = room.draw_pile
    for i = #drawPile, 1, -1 do
      local id = drawPile[i]
      if table.removeOne(suits, Fk:getCardById(id).suit) then
        table.insert(cards, id)
        if #suits == 0 then break end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, qingjuex.name, nil, true, player)
    end
  end,
}

qingjuex:addEffect(fk.Damaged, spec)
qingjuex:addEffect(fk.HpLost, spec)
qingjuex:addEffect(fk.HpRecover, spec)
--qingjuex:addEffect(fk.MaxHpChanged, spec)

qingjuex:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    if player:hasSkill(qingjuex.name) then
      return table.every(player:getCardIds("h"), function(id)
        return id == card.id or card:compareSuitWith(Fk:getCardById(id), true)
      end)
    end
  end,
})

return qingjuex
