
local fuyao = fk.CreateSkill {
  name = "fuyao",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["fuyao"] = "扶摇",
  [":fuyao"] = "转换技，出牌阶段，你可以将手牌中展示和未展示过的牌："..
  "阳：展示至两者数量相同；阴：弃置至两者数量相同。然后视为使用一张本阶段未以此法使用过的单目标普通锦囊牌。",

  ["#fuyao-yang"] = "扶摇：将手牌展示至展示和未展示牌数量相同，然后视为使用一张锦囊牌",
  ["#fuyao-yin"] = "扶摇：将手牌弃置至展示和未展示牌数量相同，然后视为使用一张锦囊牌",
  ["@@fuyao-inhand"] = "已展示",
  ["#fuyao-use"] = "扶摇：请视为使用一张单目标普通锦囊牌",

  ["$fuyao1"] = "",
  ["$fuyao2"] = "",
}

fuyao:addEffect("active", {
  anim_type = "switch",
  prompt = function(self, player, selected_cards, selected_targets)
    return "#fuyao-"..player:getSwitchSkillState(fuyao.name, false, true)
  end,
  can_use = function(self, player)
    if player:getSwitchSkillState(fuyao.name) == fk.SwitchYin then
      if player:isKongcheng() then return false end
    else
      local cards = player:getCardIds("h")
      local n = #cards
      if n % 2 == 1 then return false end
      for _, id in ipairs(cards) do
        if Fk:getCardById(id, true):getMark("@@fuyao-inhand") > 0 then
          n = n - 2
          if n < 1 then
            return false
          end
        end
      end
    end
    local ban_names = player:getTableMark("fuyao-phase")
    for _, name in ipairs(Fk:getAllCardNames("t")) do
      local card = Fk:cloneCard(name, Card.NoSuit, 0, fuyao.name)
      if not card.multiple_targets and card.skill:getMinTargetNum(player) < 2 and
        not card.is_passive and not table.contains(ban_names, name) and
        #card:getAvailableTargets(player) > 0  then
        return true
      end
    end
  end,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected, selected_targets)
    if not table.contains(player:getCardIds("h"), to_select) then return end
    if player:getSwitchSkillState(fuyao.name) == fk.SwitchYin and player:prohibitDiscard(to_select) then return end
    return true
  end,
  feasible = function(self, player, selected, selected_cards, card)
    if #selected_cards == 0 then return end
    local shown, no_shown = 0, 0
    for _, id in ipairs(player:getCardIds("h")) do
      if table.contains(selected_cards, id) then
        if player:getSwitchSkillState(fuyao.name) == fk.SwitchYang then
          shown = shown + 1
        end
      else
        if Fk:getCardById(id, true):getMark("@@fuyao-inhand") > 0 then
          shown = shown + 1
        else
          no_shown = no_shown + 1
        end
      end
    end
    return shown == no_shown
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getSwitchSkillState(fuyao.name, true) == fk.SwitchYang then
      player:showCards(effect.cards)
    else
      room:throwCard(effect.cards, fuyao.name, player, player)
    end
    if player.dead then return end
    local names = table.filter(Fk:getAllCardNames("t"), function(name)
      local card = Fk:cloneCard(name)
      return not card.multiple_targets and card.skill:getMinTargetNum(player) < 2 and
        not card.is_passive and not table.contains(player:getTableMark("fuyao-phase"), name)
    end)
    local use = room:askToUseVirtualCard(player, {
      name = names,
      skill_name = fuyao.name,
      prompt = "#fuyao-use",
      cancelable = false,
    })
    if use and not player.dead then
      room:addTableMark(player, "fuyao-phase", use.card.name)
    end
  end,
})

fuyao:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyao.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(data.cardIds) do
      if table.contains(player:getCardIds("h"), id) then
        room:setCardMark(Fk:getCardById(id, true), "@@fuyao-inhand", 1)
      end
    end
  end,
})

return fuyao
