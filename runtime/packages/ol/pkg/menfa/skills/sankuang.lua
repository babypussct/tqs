local sankuang = fk.CreateSkill{
  name = "sankuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["sankuang"] = "三恇",
  [":sankuang"] = "锁定技，当你每轮首次使用一种类别的牌后，你令一名其他角色交给你至少X张牌并获得你使用的牌（X为其满足的项数：1.场上有牌；"..
  "2.已受伤；3.体力值小于手牌数）。",

  ["#sankuang-choose"] = "三恇：令一名其他角色交给你至少“三恇”张数的牌并获得你使用的%arg",
  ["#sankuang"] = "三恇张数 %arg",
  ["#sankuang-give0"] = "三恇：交给 %src 任意张牌，获得其使用的 %arg",
  ["#sankuang-give"] = "三恇：交给 %src 至少 %arg 张牌",
  ["@sankuang-round"] = "三恇",

  ["$sankuang1"] = "人言可畏，宜常辟之。",
  ["$sankuang2"] = "天地可敬，可常惧之。",
}

Fk:addTargetTip{
  name = "sankuang",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    local n = 0
    if #to_select:getCardIds("ej") > 0 then
      n = n + 1
    end
    if to_select:isWounded() then
      n = n + 1
    end
    if to_select.hp < to_select:getHandcardNum() then
      n = n + 1
    end
    return "#sankuang:::"..n
  end,
}

sankuang:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(sankuang.name) then
      local card_type = data.card.type
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent()
      local mark_name = "sankuang_" .. data.card:getTypeString() .. "-round"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data
          if last_use.from == player and last_use.card.type == card_type then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryRound)
      end
      return mark == use_event.id and #room:getOtherPlayers(player, false) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = sankuang.name,
      prompt = "#sankuang-choose:::"..data.card:toLogString(),
      cancelable = false,
      target_tip_name = sankuang.name,
    })[1]
    if player:getMark("beishi") == 0 then
      room:setPlayerMark(player, "beishi", to.id)
      room:setPlayerMark(to, "@@beishi", 1)
    end
    local n = 0
    if #to:getCardIds("ej") > 0 then
      n = n + 1
    end
    if to:isWounded() then
      n = n + 1
    end
    if to.hp < to:getHandcardNum() then
      n = n + 1
    end
    local all_cards = to:getCardIds("he")
    if #all_cards == 0 then return false end
    local cards = {}
    if n == 0 then
      cards = room:askToCards(to, {
        min_num = 1,
        max_num = #all_cards,
        include_equip = true,
        skill_name = sankuang.name,
        prompt = "#sankuang-give0:"..player.id.."::"..data.card:toLogString(),
        cancelable = true,
      })
    elseif n >= #all_cards then
      cards = all_cards
    else
      cards = room:askToCards(to, {
        min_num = n,
        max_num = #all_cards,
        include_equip = true,
        skill_name = sankuang.name,
        prompt = "#sankuang-give:"..player.id.."::"..n,
        cancelable = false,
      })
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, sankuang.name, nil, false, to)
      if to.dead then return false end
      local card_ids = Card:getIdList(data.card)
      if #card_ids == 0 then return false end
      if data.card.type == Card.TypeEquip then
        if not table.every(card_ids, function (id)
          return room:getCardArea(id) == Card.PlayerEquip and table.contains(player:getCardIds("e"), id)
        end) then return false end
      else
        if not table.every(card_ids, function (id)
          return room:getCardArea(id) == Card.Processing
        end) then return false end
      end
      room:moveCardTo(card_ids, Player.Hand, to, fk.ReasonPrey, sankuang.name, nil, true, to)
    end
  end,
})

sankuang:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(sankuang.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@sankuang-round", data.card:getTypeString().."_char")
  end,
})

sankuang:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local types = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(types, use.card:getTypeString().."_char")
      end
    end, Player.HistoryRound)
    if #types > 0 then
      room:setPlayerMark(player, "@sankuang-round", types)
    end
  end
end)

sankuang:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@sankuang-round", 0)
end)

return sankuang
