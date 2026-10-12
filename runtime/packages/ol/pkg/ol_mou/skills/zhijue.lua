local zhijue = fk.CreateSkill{
  name = "zhijue",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["zhijue"] = "智绝",
  [":zhijue"] = "转换技，出牌阶段，阳：你可将牌堆顶的一张牌当【火攻】使用；"..
    "阴：将一种颜色的手牌置入弃牌堆（每种颜色每回合限一次），然后可视为使用其中一张基本或普通锦囊牌。"..
    "若未造成伤害，你令〖知天〗可见牌与观看牌数-1（至少为1），然后你摸2张牌。",

  [":zhijue_yang"] = "转换技，出牌阶段，<font color=\"#E0DB2F\">阳：你可将牌堆顶的一张牌当【火攻】使用；</font>"..
    "阴：将一种颜色的手牌置入弃牌堆（每种颜色每回合限一次），然后可视为使用其中一张基本或普通锦囊牌。"..
    "若未造成伤害，你令〖知天〗可见牌与观看牌数-1（至少为1），然后你摸2张牌。",

  [":zhijue_yin"] = "转换技，出牌阶段，阳：你可将牌堆顶的一张牌当【火攻】使用；<font color=\"#E0DB2F\">"..
    "阴：将一种颜色的手牌置入弃牌堆（每种颜色每回合限一次），然后可视为使用其中一张基本或普通锦囊牌。</font>"..
    "若未造成伤害，你令〖知天〗可见牌与观看牌数-1（至少为1），然后你摸2张牌。",

  ["#zhijue-yang"] = "智绝：你可将牌堆顶的一张牌当【火攻】使用",
  ["#zhijue-yin"] = "智绝：你可将一种颜色的手牌置入弃牌堆，然后可视为使用其中一张基本或普通锦囊牌",

  ["$zhijue1"] = "依天时，居地利，此计当兴人和。",
  ["$zhijue2"] = "知天意，胜人谋，此战定还旧都！",
  ["$zhijue3"] = "摇此羽扇，立唤东风！",
  ["$zhijue4"] = "亮素以谋制人，岂为人谋所制？",
  ["$zhijue5"] = "天下事将了，功成还做陇亩民。",
}

---@param id integer
---@return Card
local zhijueFireAttack = function(id)
  local card = Fk:cloneCard("fire_attack")
  card:addSubcard(id)
  card.skillName = "zhijue"
  return card
end

zhijue:addEffect("active", {
  anim_type = "offensive",
  prompt = function(self, player)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      return "#zhijue-yang"
    else
      return "#zhijue-yin"
    end
  end,
  interaction = function(self, player)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      return
    else
      local all_choices = {"red", "black"}
      local choices = {}
      for _, cid in ipairs(player:getCardIds("h")) do
        table.insertIfNeed(choices, Fk:getCardById(cid):getColorString())
      end
      local mark = player:getTableMark("zhijue_color-turn")
      if #mark > 0 then
        table.removeOne(choices, mark[1])
      end
      return UI.OptionBox {
        options = choices,
        all_options = all_choices,
        direct_send = true
      }
    end
  end,
  can_use = function(self, player)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      return #Fk:currentRoom().draw_pile > 0
    else
      return #player:getTableMark("zhijue_color-turn") < 2
    end
  end,
  expand_pile = function (self, player)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      local drawPile = Fk:currentRoom().draw_pile
      if #drawPile > 0 then
        return { drawPile[1] }
      end
    end
    return {}
  end,
  card_filter = function (self, player, to_select, selected, selected_targets)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      local drawPile = Fk:currentRoom().draw_pile
      if #drawPile > 0 then
        return to_select == drawPile[1] and player:canUse(zhijueFireAttack(to_select))
      end
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang and #selected_cards == 1 then
      local card = zhijueFireAttack(selected_cards[1])
      return card.skill:targetFilter(player, to_select, selected, selected_cards, card, Util.DummyTable)
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      if #selected_cards == 1 then
        local card = zhijueFireAttack(selected_cards[1])
        return card.skill:feasible(player, selected, selected_cards, card)
      end
    else
      return true
    end
  end,
  on_cost = function(self, player, data, extra_data)
    local cost = {} ---@type CostData
    if player:getSwitchSkillState(zhijue.name, false) == fk.SwitchYang then
      cost.audio_index = {1,2,3}
    else
      cost.audio_index = {4,5}
    end
    return cost
  end,
  on_use = function(self, room, effect)
    local skillName = zhijue.name
    local player = effect.from
    local draw2 = true
    if player:getSwitchSkillState(zhijue.name, true) == fk.SwitchYang then
      local use = {---@type UseCardDataSpec
        from = effect.from,
        card = zhijueFireAttack(effect.cards[1]),
        tos = effect.tos
      }
      room:useCard(use)
      if use.damageDealt then
        draw2 = false
      end
    else
      room:addTableMark(player, "zhijue_color-turn", self.interaction.data)
      local color = (self.interaction.data == "red") and Card.Red or Card.Black
      local names = {}
      local c
      local cards = table.filter(player:getCardIds("h"), function(cid)
        c = Fk:getCardById(cid)
        if c.color == color then
          if c.type == Card.TypeBasic or c:isCommonTrick() then
            table.insertIfNeed(names, c.trueName)
          end
          return true
        end
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, nil, true, player)
        if player.dead then return end
        local use = room:askToUseVirtualCard(player, {
          name = names,
          skill_name = skillName,
          cancelable = true,
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
        })
        if use and use.damageDealt then
          draw2 = false
        end
      end
    end
    if draw2 and not player.dead and player:getMark("@[zhitian]") > 1 then
      room:removePlayerMark(player, "@[zhitian]")
      player:drawCards(2, skillName)
    end
  end,
})

zhijue:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "zhijue_color-turn", 0)
end)

return zhijue
