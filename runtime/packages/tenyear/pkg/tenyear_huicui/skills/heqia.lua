local heqia = fk.CreateSkill {
  name = "heqia",
}

Fk:loadTranslationTable{
  ["heqia"] = "和洽",
  [":heqia"] = "出牌阶段开始时，你可以选择一项：1.你交给一名其他角色至少一张牌；2.令一名有手牌的其他角色交给你至少一张牌。然后获得牌的角色"..
  "可以将一张手牌当任意基本牌使用（无距离限制），且此牌目标上限改为X（X为其本次获得的牌数）。",

  ["#heqia-invoke"] = "和洽：交给一名其他角色至少一张牌，或选择一名角色将至少一张牌交给你",
  ["heqia_give"] = "交给一名其他角色任意张牌",
  ["heqia_prey"] = "令一名角色将至少一张牌交给你",
  ["#heqia-give"] = "和洽：交给 %src 至少一张牌",
  ["#heqia-use"] = "和洽：你可以将一张手牌当任意基本牌使用，可以指定%arg个目标",

  ["$heqia1"] = "和洽不基，贵贱无司。",
  ["$heqia2"] = "教化大行，天下和洽。",
}

heqia:addAuxActiveSkill("heqia_active", {
  min_card_num = function(self)
    if self.interaction.data == "heqia_give" then
      return 1
    end
    return 0
  end,
  target_num = 1,
  interaction_helper = function(self, player)
    local choices = {}
    if not player:isNude() then
      table.insert(choices, "heqia_give")
    end
    if table.find(Fk:currentRoom().alive_players, function(p)
      return player ~= p and not p:isNude()
    end) then
      table.insert(choices, "heqia_prey")
    end
    return UI.OptionBox {options = choices, all_options = {"heqia_give", "heqia_prey"}}
  end,
  fix_targets = function(self, player, selected_cards, card, extra_data)
    if self.interaction.data == nil then return {} end
  end,
  card_filter = function(self, player, to_select, selected)
    return self.interaction.data == "heqia_give"
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if self.interaction.data == nil then return false end
    if #selected == 0 and to_select ~= player then
      if self.interaction.data == "heqia_prey" then
        return not to_select:isNude()
      else
        return true
      end
    end
  end,
})

heqia:addAuxActiveSkill("heqia_viewas", {
  handly_pile = true,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames("heqia", all_names, selected_cards, nil, { bypass_distances = true, bypass_times = true })
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  fix_targets = function(self, player, selected_cards, card, extra_data)
    if self.interaction.data == nil then return {} end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return end
    if #selected < self.heqia_num then
      local card = Fk:cloneCard(self.interaction.data, nil, nil, heqia.name, selected_cards)
      if #selected == 0 then
        return card.skill:targetFilter(player, to_select, {}, {}, card, { bypass_distances = true, bypass_times = true })
      else
        return card.skill:modTargetFilter(player, to_select, selected, card, { bypass_distances = true, bypass_times = true })
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data, nil, nil, heqia.name, selected_cards)
    if card.skill:getMinTargetNum(player) == 0 then
      return (#selected == 0 or table.contains(selected, player)) and
        card.skill:feasible(player, selected, {}, card)
    else
      return #selected > 0
    end
  end,
})

heqia:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(heqia.name) and player.phase == Player.Play and
      (not player:isNude() or
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "heqia_active",
      prompt = "#heqia-invoke",
      cancelable = true,
      no_indicate = false,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from, to, cards = player, event:getCostData(self).tos[1], event:getCostData(self).cards
    if #cards == 0 then
      from, to = event:getCostData(self).tos[1], player
      cards = room:askToCards(from, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = heqia.name,
        cancelable = false,
        prompt = "#heqia-give:"..player.id,
      })
    end
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, heqia.name, nil, false, from)
    if to.dead or to:isKongcheng() then return end
    local success, dat = room:askToUseActiveSkill(to, {
      skill_name = "heqia_viewas",
      prompt = "#heqia-use:::"..#cards,
      cancelable = true,
      extra_data = {
        heqia_num = #cards,
      }
    })
    if success and dat then
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      room:useCard{
        from = to,
        tos = dat.targets,
        card = card,
        extraUse = true,
      }
    end
  end,
})

return heqia
