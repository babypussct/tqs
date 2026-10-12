local poyin = fk.CreateSkill {
  name = "poyin",
  tags = { Skill.Compulsory }
}

Fk:loadTranslationTable{
  ["poyin"] = "迫饮",
  [":poyin"] = "锁定技，回合开始时，你摸体力上限张牌，并选择其中已损失体力值或当前体力值张牌视为【酒】；"..
  "回合结束时，手牌数全场最多的角色猜测你手牌中【酒】数是否大于其他手牌数，若猜对，其从牌堆中获得一张【杀】，若猜错，你可以重铸任意张牌。",

  ["#poyin-ask"] = "迫饮：请选择其中部分牌视为【酒】",
  ["poyin_losthp"] = "已损失体力",
  ["poyin_hp"] = "当前体力",
  ["@@poyin-inhand"] = "迫饮",
  ["#poyin-choice"] = "迫饮：猜测 %src 的【酒】数是否大于其他手牌数",
  ["#poyin-recast"] = "迫饮：你可以重铸任意张牌",

  ["$poyin1"] = "黑厮不讲情面！哪有不吃酒还要被罚的道理！",
  ["$poyin2"] = "适才服了汤药，医嘱不可饮酒~"
}

poyin:addAuxActiveSkill("poyin_active", {
  target_num = 0,
  interaction = UI.ComboBox { choices = { "poyin_losthp", "poyin_hp" }},
  card_filter = function(self, player, to_select, selected)
    if table.contains(self.cards, to_select) then
      if self.interaction.data == "poyin_losthp" then
        return #selected < player:getLostHp()
      elseif self.interaction.data == "poyin_hp" then
        return #selected < player.hp
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if #selected_cards == 0 then return end
    if self.interaction.data == "poyin_losthp" then
      return #selected_cards == player:getLostHp()
    elseif self.interaction.data == "poyin_hp" then
      return #selected_cards == player.hp
    end
  end,
})

poyin:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(player.maxHp, poyin.name)
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    if not (#cards <= player:getLostHp() and #cards <= player.hp) then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "poyin_active",
        prompt = "#poyin-ask",
        cancelable = false,
        extra_data = {
          cards = cards,
        }
      })
      if not (success and dat) then
        dat = {}
        local min = math.min(player:getLostHp(), player.hp)
        if min == 0 then
          min = math.max(player:getLostHp(), player.hp)
        end
        dat.cards = room:tableRandomPick(cards, min)
      end
      cards = dat.cards
    end
    if #cards > 0 then
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@poyin-inhand", 1)
      end
      player:filterHandcards()
    end
  end,
})

poyin:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return table.every(room.alive_players, function (p2)
        return p:getHandcardNum() >= p2:getHandcardNum()
      end)
    end)
    for _, to in ipairs(targets) do
      if not to.dead then
        local choice = room:askToChoice(to, {
          choices = { "yes", "no" },
          skill_name = poyin.name,
          prompt = "#poyin-choice:"..player.id,
        })
        local n = #table.filter(player:getCardIds("h"), function (id)
          return Fk:getCardById(id).trueName == "analeptic"
        end)
        if (choice == "yes" and n > player:getHandcardNum() / 2) or
          (choice == "no" and n <= player:getHandcardNum() / 2) then
          local card = room:getCardsFromPileByRule("slash")
          if #card > 0 then
            room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonJustMove, poyin.name, nil, false, player)
          end
        elseif not player:isNude() then
          local cards = room:askToCards(player, {
            min_num = 1,
            max_num = 999,
            include_equip = true,
            prompt = "#poyin-recast",
            skill_name = poyin.name,
            cancelable = true,
          })
          if #cards > 0 then
            room:recastCard(cards, player, poyin.name)
          end
        end
        if player.dead then return end
      end
    end
  end,
})

poyin:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@poyin-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("analeptic", card.suit, card.number)
  end,
})

return poyin
