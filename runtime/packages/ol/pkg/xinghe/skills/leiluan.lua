local leiluan = fk.CreateSkill {
  name = "leiluan",
}

Fk:loadTranslationTable {
  ["leiluan"] = "累卵",
  [":leiluan"] = "你可以将X张牌当一张你本轮未使用过的基本牌使用（X为已连环的角色数且至少为1）。" ..
      "若你以此法失去最后的手牌，你摸两张牌，从本回合弃牌堆中获得一张普通锦囊牌，然后此技能失效，直到你下次受到伤害后。",

  ["#leiluan"] = "累卵：你可以将%arg张牌当基本牌使用",
  ["#leiluan-prey"] = "累卵：获得其中一张牌",
  ["@@leiluan"] = "累卵已失效",

  ["$leiluan1"] = "安有巢毁而卵不破乎！",
  ["$leiluan2"] = "抱木渡河，木既沉，渡者何谈生。",
}

local function leiluanCount()
  local n = #table.filter(Fk:currentRoom().alive_players, function(p)
    return p.chained
  end)
  return math.max(n, 1)
end

leiluan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function(self, player)
    return "#leiluan:::" .. leiluanCount()
  end,
  handly_pile = true,
  filter_pattern = function(self, player, card_name)
    local x = leiluanCount()
    return {
      max_num = x,
      min_num = x,
      pattern = ".",
    }
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(leiluan.name, all_names, selected_cards, player:getTableMark("leiluan-round"))
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= leiluanCount() then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, leiluan.name, cards)
  end,
  before_use = function(self, player, use)
    if not player:isKongcheng() and
        table.every(player:getCardIds("h"), function(id)
          return table.contains(use.card.subcards, id)
        end) then
      use.extra_data = use.extra_data or {}
      use.extra_data.leiluan = player
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@leiluan") == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("@@leiluan") == 0 and
        #player:getViewAsCardNames(leiluan.name, Fk:getAllCardNames("b"), nil, player:getTableMark("leiluan-round")) > 0
  end,
})

leiluan:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.leiluan == player and player:hasSkill(leiluan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, leiluan.name)
    if player.dead then return end
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):isCommonTrick() and table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    if #cards > 0 then
      local card = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = { { "pile_discard", cards } } },
        skill_name = leiluan.name,
        prompt = "#leiluan-prey",
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, leiluan.name, nil, true, player)
      if player.dead then return end
    end
    if player:hasSkill(leiluan.name, true) then
      room:setPlayerMark(player, "@@leiluan", 1)
    end
  end,
})

leiluan:addEffect(fk.Damaged, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@leiluan") > 0 and player:hasSkill(leiluan.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@leiluan", 0)
  end,
})

leiluan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(leiluan.name, true) and data.card.type == Card.TypeBasic
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "leiluan-round", data.card.trueName)
  end,
})

leiluan:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.trueName)
      end
    end, Player.HistoryRound)
    room:setPlayerMark(player, "leiluan-round", names)
  end
end)

leiluan:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "leiluan-round", 0)
  player.room:setPlayerMark(player, "@@leiluan", 0)
end)

return leiluan
