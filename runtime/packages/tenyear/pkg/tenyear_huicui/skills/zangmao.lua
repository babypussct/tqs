local zangmao = fk.CreateSkill {
  name = "zangmao",
}

Fk:loadTranslationTable{
  ["zangmao"] = "驵贸",
  [":zangmao"] = "出牌阶段限三次，你可以：1.弃置任意张<font color='red'>♦</font>牌，然后从牌堆或弃牌堆随机获得等量张坐骑牌；"..
    "2.交给一名其他角色一张<font color='red'>♦</font>牌，然后获得其装备区一张坐骑牌；"..
    "3.将一张坐骑牌置入一名其他角色装备区，然后其交给你两张手牌。",

  ["#zangmao-invoke"] = "驵贸：你可选择一项发动",
  ["zangmao_search"] = "检索坐骑",
  ["zangmao_buy"] = "购买坐骑",
  ["zangmao_sell"] = "出售坐骑",
  ["#zangmao-search"] = "驵贸：弃置任意张<font color='red'>♦</font>牌，从牌堆或弃牌堆随机获得等量张坐骑牌",
  ["#zangmao-buy"] = "驵贸：交给一名其他角色一张<font color='red'>♦</font>牌，获得其装备区一张坐骑牌",
  ["#zangmao-sell"] = "驵贸：将一张坐骑牌置入一名其他角色装备区，其交给你两张手牌",
  ["#zangmao-give"] = "驵贸：请交给 %src 两张手牌",

  ["$zangmao1"] = "不才走南闯北，做得些贩马生意。",
  ["$zangmao2"] = "幽州驹，冀州马，铜钱换马，童叟无欺！",
}

zangmao:addEffect("active", {
  anim_type = "support",
  prompt = function(self, pplayer, selected_cards)
    if self.interaction.data then
      return "#zangmao-" .. string.sub(self.interaction.data, 9)
    end
    return "#zangmao-invoke"
  end,
  max_phase_use_time = 3,
  times = function (self, player)
    return player.phase == Player.Play and 3 - player:usedEffectTimes(zangmao.name, Player.HistoryPhase) or -1
  end,
  interaction = UI.ComboBox { choices = {"zangmao_search", "zangmao_buy", "zangmao_sell"} },
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    local choice = self.interaction.data
    if choice == "zangmao_search" then
      return card.suit == Card.Diamond and not player:prohibitDiscard(card)
    elseif choice == "zangmao_buy" then
      return #selected == 0 and card.suit == Card.Diamond
    elseif choice == "zangmao_sell" then
      return #selected == 0 and card.sub_type == Card.SubtypeDefensiveRide or card.sub_type == Card.SubtypeOffensiveRide
    end
  end,
  target_num = function(self, player)
    return self.interaction.data == "zangmao_search" and 0 or 1
  end,
  fix_targets = function(self, player, selected_cards, card, extra_data)
    if self.interaction.data == "zangmao_search" then return {} end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local choice = self.interaction.data
    if choice == "zangmao_buy" then
      return #selected == 0 and to_select ~= player
    elseif choice == "zangmao_sell" then
      return #selected == 0 and to_select ~= player and
        #selected_cards > 0 and to_select:canMoveCardIntoEquip(selected_cards[1], false)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = self.interaction.data
    if choice == "zangmao_search" then
      local x = #effect.cards
      room:throwCard(effect.cards, zangmao.name, player, player)
      if player.dead then return end
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|defensive_ride,offensive_ride", x)
      if #cards < x then
        --待测：是否同时移动
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|defensive_ride,offensive_ride", x - #cards, "discardPile"))
      end
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, zangmao.name)
      end
    elseif choice == "zangmao_buy" then
      local to = effect.tos[1]
      room:obtainCard(to, effect.cards, false, fk.ReasonGive, player, zangmao.name)
      if player.dead or to.dead then return end
      local ride_tab = {}
      for _, card in ipairs(to:getEquipCards()) do
        if card.sub_type == Card.SubtypeDefensiveRide or card.sub_type == Card.SubtypeOffensiveRide then
          table.insert(ride_tab, card:getEffectiveId())
        end
      end
      if #ride_tab == 0 then return end
      local id = room:askToChooseCard(player, {
        target = to,
        flag = { card_data = { { "equip_horse", ride_tab } } },
        skill_name = zangmao.name,
      })
      room:obtainCard(player, id, true, fk.ReasonPrey, player, zangmao.name)
    elseif choice == "zangmao_sell" then
      local to = effect.tos[1]
      room:moveCardIntoEquip(to, effect.cards[1], zangmao.name, false, player)
      if player.dead or to:isKongcheng() then return end
      local cards = room:askToCards(to, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = zangmao.name,
        prompt = "#zangmao-give:"..player.id,
        cancelable = false,
      })
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, zangmao.name, nil, false, to)
    end
  end,
})

return zangmao
