local silun = fk.CreateSkill {
  name = "silun",
}

Fk:loadTranslationTable{
  ["silun"] = "四论",
  [":silun"] = "准备阶段或当你受到伤害后，你可以摸四张牌，然后将四张牌依次置于场上、牌堆顶或牌堆底，装备区的牌数因此变化的角色复原其武将牌。",

  ["#silun-card"] = "四论：将一张牌置于场上、牌堆顶或牌堆底（第%arg张/共4张）",
  ["Field"] = "场上",

  ["$silun1"] = "习守静之术，行务时之风。",
  ["$silun2"] = "纵笔瑞白雀，满座尽高朋。",
}

silun:addAuxActiveSkill("silun_active", {
  card_num = 1,
  max_target_num = 1,
  interaction = UI.ComboBox {choices = {"Field", "Top", "Bottom"}},
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "Field" then
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip or card.sub_type == Card.SubtypeDelayedTrick
      end
      return true
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and self.interaction.data == "Field" and #selected_cards == 1 then
      local card = Fk:getCardById(selected_cards[1])
      if card.type == Card.TypeEquip then
        return to_select:hasEmptyEquipSlot(card.sub_type)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        return not to_select:isProhibited(to_select, card)
      end
    end
    return false
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if self.interaction.data == "Field" then
        return #selected == 1
      else
        return #selected == 0
      end
    end
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(4, silun.name)
    for i = 1, 4, 1 do
      if player.dead or player:isNude() then return end
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "silun_active",
        prompt = "#silun-card:::"..i,
        cancelable = false,
      })
      if not (success and dat) then
        dat = {}
        dat.cards = {player:getCardIds("he")[1]}
        dat.interaction = "Top"
      end
      local reset = table.contains(player:getCardIds("e"), dat.cards[1])
      if dat.interaction == "Field" then
        local to = dat.targets[1]
        local card = Fk:getCardById(dat.cards[1])
        if card.type == Card.TypeEquip then
          room:moveCardIntoEquip(to, dat.cards, silun.name, false, player)
          if reset and not player.dead then
            player:reset()
          end
          if not to.dead then
            to:reset()
          end
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          room:moveCardTo(card, Card.PlayerJudge, to, fk.ReasonPut, silun.name, nil, true, player)
        end
      else
        local drawPilePosition = 1
        if dat.interaction == "Bottom" then
          drawPilePosition = -1
        end
        room:moveCards({
          ids = dat.cards,
          from = player,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = silun.name,
          drawPilePosition = drawPilePosition,
          moveVisible = true,
        })
      end
    end
  end,
}

silun:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(silun.name) and player.phase == Player.Start
  end,
  on_use = spec.on_use,
})

silun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(silun.name)
  end,
  on_use = spec.on_use,
})

silun:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 4)
    end) >= 0
  end,
})

return silun
