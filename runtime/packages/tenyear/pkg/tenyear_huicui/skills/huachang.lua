local huachang = fk.CreateSkill {
  name = "huachang",
}

Fk:loadTranslationTable{
  ["huachang"] = "华裳",
  [":huachang"] = "游戏开始时，将每种颜色各一张牌置入你的装备区。<br>"..
  "若你的装备区有两种颜色的牌，你使用牌无距离限制。<br>"..
  "当你使用一张牌结算后，你可以将一张相同花色的非装备手牌置入装备区。<br>"..
  "当你失去手牌后，你将手牌补至等同于你装备区牌的花色数。",

  ["#huachang-invoke"] = "华裳：你可以将一张%arg的非装备手牌置入装备区",

  ["$huachang1"] = "妾若布衣荆钗，岂非明珠投暗？",
  ["$huachang2"] = "妾生千金之家，当配万乘之服。",
}

huachang:addAuxActiveSkill("huachang_active", {
  card_num = 1,
  target_num = 0,
  interaction = function(self, player)
    return UI.OptionBox { options = player:getAvailableEquipSlots(), direct_send = true }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and
      Fk:getCardById(to_select).type ~= Card.TypeEquip and
      Fk:getCardById(to_select).suit == self.suit
  end,
})

local mapper = {
  [Player.WeaponSlot] = "weapon",
  [Player.ArmorSlot] = "armor",
  [Player.OffensiveRideSlot] = "offensive_horse",
  [Player.DefensiveRideSlot] = "defensive_horse",
  [Player.TreasureSlot] = "treasure",
}

huachang:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huachang.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards, colors = {}, { Card.Black, Card.Red }
    for _, id in ipairs(room.draw_pile) do
      if table.removeOne(colors, Fk:getCardById(id).color) then
        table.insert(cards, id)

        if #colors == 0 then
          break
        end
      end
    end

    local num = #cards
    for i = 1, num do
      if player.dead then return end

      local availableSlots = table.filter(player.equipSlots,
        function(slot) return player:hasEmptyEquipSlot(Util.convertSubtypeAndEquipSlot(slot))
      end)

      if #availableSlots == 0 then
        return
      end

      local id = cards[i]
      local card = Fk:cloneCard( mapper[room:tableRandomPick(availableSlots)].."__huachang")
      card:addSubcard(id)
      room:moveCardIntoEquip(player, card, huachang.name, true, player)
    end
  end,
})

huachang:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    if player:hasSkill(huachang.name) and card then
      local colors = {}
      for _, id in ipairs(player:getCardIds("e")) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      return #colors > 1
    end
  end,
})

huachang:addEffect(fk.CardUseFinished, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huachang.name) and
      not player:isKongcheng() and #player:getAvailableEquipSlots() > 0 and data.card.suit ~= Card.NoSuit
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "huachang_active",
      prompt = "#huachang-invoke:::"..data.card:getSuitString(true),
      extra_data = {
        suit = data.card.suit,
      },
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local card = Fk:cloneCard(mapper[event:getCostData(self).choice].."__huachang")
    card:addSubcard(id)
    room:moveCardIntoEquip(player, card, huachang.name, true, player)
  end,
})

huachang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(huachang.name) and player:getHandcardNum() < #player:getCardIds("e") then
      local suits = {}
      for _, id in ipairs(player:getCardIds("e")) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      if player:getHandcardNum() < #suits then
        for _, move in ipairs(data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                event:setCostData(self, {choice = #suits - player:getHandcardNum()})
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, huachang.name)
  end,
})

return huachang
