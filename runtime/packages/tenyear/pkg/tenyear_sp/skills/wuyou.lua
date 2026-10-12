local wuyou = fk.CreateSkill {
  name = "wuyou",
  attached_skill_name = "wuyou&",
}

Fk:loadTranslationTable {
  ["wuyou"] = "武佑",
  [":wuyou"] = "每名角色的出牌阶段限一次，其可以交给你一张手牌，然后你可以从五个随机非装备牌名中选择一个并交给其一张手牌，" ..
      "此牌视为你选择的牌名且无距离次数限制。（若为你则跳过交给手牌）",

  ["#wuyou"] = "武佑：从五个随机牌名中选择，令一张手牌视为你声明的牌",
  ["#wuyou-declare"] = "武佑：将一张手牌交给 %dest 并令此牌视为声明的牌名",
  ["@@wuyou-inhand"] = "武佑",

  ["$wuyou1"] = "秉赤面，观春秋，虓菟踏纛，汗青著峥嵘！",
  ["$wuyou2"] = "着青袍，饮温酒，五关已过，来将且通名！",
}

wuyou:addAuxActiveSkill("wuyou_declare", {
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  interaction_helper = function(self, player)
    return UI.CardNameBox { choices = self.interaction_choices }
  end,
})

wuyou:addEffect("active", {
  prompt = "#wuyou",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(wuyou.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos and #effect.tos > 0 and effect.tos[1] or player
    local card_names = player:getMark("wuyou_names")
    if type(card_names) ~= "table" then
      card_names = {}
      local tmp_names = {}
      local card, index
      for _, name in ipairs(Fk:getAllCardNames("btd")) do
        card = Fk.all_card_types[name]
        if not card.is_derived then
          index = table.indexOf(tmp_names, card.trueName)
          if index == -1 then
            table.insert(tmp_names, card.trueName)
            table.insert(card_names, { card.name })
          else
            table.insertIfNeed(card_names[index], card.name)
          end
        end
      end
      room:setPlayerMark(player, "wuyou_names", card_names)
    end
    if #card_names == 0 then return end
    card_names = table.map(room:tableRandomPick(card_names, 5), function(card_list)
      return room:tableRandomPick(card_list)
    end)
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "wuyou_declare",
      prompt = "#wuyou-declare::" .. target.id,
      cancelable = true,
      extra_data = { interaction_choices = card_names }
    })
    if not success or dat==nil then return end
    local id = dat.cards[1]
    local card_name = dat.interaction
    if target == player then
      room:setCardMark(Fk:getCardById(id), "@@wuyou-inhand", card_name)
      Fk:filterCard(id, player)
    else
      room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player,
        { "@@wuyou-inhand", card_name })
    end
  end,
})

wuyou:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@wuyou-inhand") ~= 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card:getMark("@@wuyou-inhand"), card.suit, card.number)
  end,
})

wuyou:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@wuyou-inhand") ~= 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card:getMark("@@wuyou-inhand") ~= 0
  end,
})

wuyou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:getMark("@@wuyou-inhand") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

return wuyou
