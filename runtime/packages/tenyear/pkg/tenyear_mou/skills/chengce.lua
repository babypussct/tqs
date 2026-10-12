
local chengce = fk.CreateSkill {
  name = "chengce",
}

Fk:loadTranslationTable{
  ["chengce"] = "呈策",
  [":chengce"] = "每轮开始时，你可以观看牌堆顶两张牌并用任意张手牌替换其中等量牌，然后你令一名其他角色观看牌堆顶两张牌并获得其中一张。"..
  "若其获得的牌为非伤害牌，你获得三张非伤害牌，其获得〖心战〗直到本轮结束；"..
  "若其获得的牌为伤害牌，你获得三张伤害牌，其随机三张非伤害手牌视为【杀】直到本轮结束。",

  ["#chengce-invoke"] = "呈策：你可以观看牌堆顶两张牌并用任意张手牌替换其中等量牌",
  ["#chengce-choose"] = "呈策：令一名其他角色观看牌堆顶两张牌并获得其中一张",
  ["#chengce-prey"] = "呈策：获得其中一张牌，根据是否为伤害牌执行效果",
  ["@@chengce"] = "呈策 防止伤害",

  ["$chengce1"] = "",
  ["$chengce2"] = "",
}

chengce:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chengce.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengce.name,
      prompt = "#chengce-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToArrangeCards(player, {
      skill_name = chengce.name,
      card_map = {
        "pile_draw", room:getNCards(2),
        "$Hand", player:getCardIds("h"),
      },
      prompt = "#chengce-invoke",
      free_arrange = false,
    })
    local cards1 = table.filter(result[1], function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    local cards2 = table.filter(result[2], function (id)
      return table.contains(room.draw_pile, id)
    end)
    room:swapCardsWithPile(player, cards1, cards2, chengce.name, "Top")
    if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#chengce-choose",
      skill_name = chengce.name,
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(to, {
      target = to,
      flag = { card_data = { { "pile_draw", room:getNCards(2) } } },
      skill_name = chengce.name,
      prompt = "#chengce-prey",
    })
    local yes = Fk:getCardById(card).is_damage_card
    room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonJustMove, chengce.name, nil, false, to)
    if yes then
      if not player.dead then
        local cards = table.filter(room.draw_pile, function (id)
          return Fk:getCardById(id).is_damage_card
        end)
        if #cards > 0 then
          room:moveCardTo(room:tableRandomPick(cards, 3), Card.PlayerHand, player, fk.ReasonJustMove, chengce.name, nil, false, player)
        end
      end
      if not to:isKongcheng() then
        local cards = table.filter(to:getCardIds("h"), function (id)
          return not Fk:getCardById(id).is_damage_card
        end)
        if #cards > 0 then
          cards = room:tableRandomPick(cards, 3)
          for _, id in ipairs(cards) do
            room:setCardMark(Fk:getCardById(id), "chengce-inhand-round", 1)
          end
          to:filterHandcards()
        end
      end
    else
      if not player.dead then
        --room:setPlayerMark(player, "@@chengce", 1)
        local cards = table.filter(room.draw_pile, function (id)
          return not Fk:getCardById(id).is_damage_card
        end)
        if #cards > 0 then
          room:moveCardTo(room:tableRandomPick(cards, 3), Card.PlayerHand, player, fk.ReasonJustMove, chengce.name, nil, false, player)
        end
      end
      if not to.dead then
        room:handleAddLoseSkills(to, "ty__xinzhan")
        room.logic:getCurrentEvent():findParent(GameEvent.Round, true):addCleaner(function()
          room:handleAddLoseSkills(to, "-ty__xinzhan")
        end)
      end
    end
  end,
})

chengce:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("chengce-inhand-round") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

chengce:addEffect(fk.DetermineDamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@chengce") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@chengce", 0)
    data:preventDamage()
  end,
})

return chengce
