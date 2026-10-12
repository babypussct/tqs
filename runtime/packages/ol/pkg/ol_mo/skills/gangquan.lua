local gangquan = fk.CreateSkill{
  name = "gangquan",
}

Fk:loadTranslationTable {
  ["gangquan"] = "罡拳",
  [":gangquan"] = "若你使用的上一张牌为“炁”，你可以将一张装备牌当指定相邻角色为目标的火【杀】使用；"..
    "否则，你可以将一张锦囊牌当【决斗】使用。",

  ["#gangquan-fire__slash"] = "罡拳：将一张装备牌当指定相邻角色为目标的火【杀】使用",
  ["#gangquan-duel"] = "罡拳：将一张锦囊牌当【决斗】使用",
  ["@gangquan"] = "罡拳",

  ["$gangquan1"] = "罡风贯耳，为我战歌！",
  ["$gangquan2"] = "用这拳头，打破一切！",
}

gangquan:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash,duel",
  prompt = function(self, player)
    return "#gangquan-" .. player:getMark("@gangquan")
  end,
  handly_pile = true,
  filter_pattern = function (self, player, card_name)
    local name = player:getMark("@gangquan")
    if name == "fire__slash" then
      return {
        max_num = 1,
        min_num = 1,
        pattern = ".|.|.|.|.|equip",
      }
    elseif name == "duel" then
      return {
        max_num = 1,
        min_num = 1,
        pattern = ".|.|.|.|.|trick",
      }
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local name = player:getMark("@gangquan")
    local c = Fk:cloneCard(name)
    c.skillName = gangquan.name
    c:addSubcard(cards[1])
    if name == "fire__slash" then
      c.skill = Fk.skills["gangquan__slash_skill"]
    end
    return c
  end,
  before_use = function(self, player, use)
    if use.card.name == "fire__slash" then
      local c = Fk:cloneCard("fire__slash")
      c.skillName = gangquan.name
      c:addSubcard(use.card.subcards[1])
      use.card = c
      local room = player.room
      use.tos = table.filter(room.alive_players, function (p)
        return p ~= player and (p:getNextAlive() == player or player:getNextAlive() == p) and not player:isProhibited(p, c)
      end)
    end
  end,
  enabled_at_play = function(self, player)
    local name = player:getMark("@gangquan")
    if name == "duel" then
      return true
    elseif name == "fire__slash" then
      local slash = Fk:cloneCard("fire__slash")
      slash.skillName = gangquan.name
      if player:prohibitUse(slash) then return false end
      local next = player:getNextAlive()
      if next == player then return false end
      if not player:isProhibited(next, slash) and slash.skill:withinTimesLimit(player, Player.HistoryPhase, slash, "slash", next) then return true end
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p:getNextAlive() == player then
          return not player:isProhibited(p, slash) and slash.skill:withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p)
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local name = player:getMark("@gangquan")
    local card = Fk:cloneCard(name)
    card.skillName = gangquan.name
    if not Exppattern:Parse(Fk.currentResponsePattern):match(card) then return false end
    if name == "fire__slash" then
      local extra_data = player:getMark("gangquan_extradata")
      if extra_data == 0 then
        extra_data = nil
      else
        extra_data.bypass_distances = true
      end
      local next = player:getNextAlive()
      if next == player then return false end
      if player:canUseTo(card, next, extra_data) then return true end
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p:getNextAlive() == player then
          return player:canUseTo(card, p, extra_data)
        end
      end
    end
    return true
  end,
})

gangquan:addEffect(fk.HandleAskForPlayCard, {
  --FIXME：由于enabled_at_response获取不到extra_data，权且如此
  can_refresh = function(self, event, target, player, data)
    return data.user == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "gangquan_extradata", data.extraData)
  end,
})

gangquan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(gangquan.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local name = "duel"
    local mark = player:getTableMark("duoqi_cards")
    --实测所有实体牌均为“炁”才算
    local cards = Card:getIdList(data.card)
    if #cards > 0 and table.every(cards, function (id)
      return table.contains(mark, id)
    end) then
      name = "fire__slash"
    end
    if player:getMark("@gangquan") ~= name then
      player.room:setPlayerMark(player, "@gangquan", name)
    end
  end,
})

gangquan:addAcquireEffect(function (self, player, is_death)
  local room = player.room
  local name = "duel"
  room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
    if e.data.from == player then
      local mark = player:getTableMark("duoqi_cards")
      local cards = Card:getIdList(e.data.card)
        if #cards > 0 and table.every(cards, function (id)
        return table.contains(mark, id)
      end) then
        name = "fire__slash"
      end
      return true
    end
  end, 1)
  room:setPlayerMark(player, "@gangquan", name)
end)

gangquan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@gangquan", 0)
end)

return gangquan