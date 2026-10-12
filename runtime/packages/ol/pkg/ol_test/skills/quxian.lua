
local quxian = fk.CreateSkill{
  name = "ol__quxian",
  max_branches_use_time = {
    ["prey"] = {
      [Player.HistoryRound] = 1
    },
    ["discard"] = {
      [Player.HistoryRound] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["ol__quxian"] = "驱险",
  [":ol__quxian"] = "每轮各限一次，其他角色使用伤害牌指定你为目标后，你可以选择一项：从牌堆中获得一张同名牌；弃置一张同名牌令此牌无效。",

  ["#ol__quxian-invoke"] = "驱险：你可以选择一项",
  ["ol__quxian_prey"] = "获得一张【%arg】",
  ["ol__quxian_discard"] = "弃一张【%arg】，令此牌对你无效",

  ["$ol__quxian1"] = "",
  ["$ol__quxian2"] = "",
}

quxian:addAuxActiveSkill("#ol__quxian_active", {
  min_card_num = 0,
  max_card_num = 1,
  target_num = 0,
  interaction = function(self, player)
    local name = self.card_name
    local choices = {}
    if quxian:withinBranchTimesLimit(player, "prey", Player.HistoryRound) then
      table.insert(choices, "ol__quxian_prey:::"..name)
    end
    if quxian:withinBranchTimesLimit(player, "discard", Player.HistoryRound) then
      table.insert(choices, "ol__quxian_discard:::"..name)
    end
    return UI.OptionBox { options = choices, direct_send = true }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select) and
      Fk:getCardById(to_select).trueName == self.card_name
  end,
  refresh_interaction = function (self, player, selected_cards, selected_targets, extra_data)
    local name = self.card_name
    if #selected_cards == 0 then
      return { "ol__quxian_prey:::"..name }
    else
      return { "ol__quxian_discard:::"..name }
    end
  end,
})

quxian:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(quxian.name) and
      data.from ~= player and data.card.is_damage_card then
      if quxian:withinBranchTimesLimit(player, "prey", Player.HistoryRound) then
        return true
      else
        return quxian:withinBranchTimesLimit(player, "discard", Player.HistoryRound) and not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#ol__quxian_active",
      prompt = "#ol__quxian-invoke",
      cancelable = true,
      extra_data = {
        card_name = data.card.trueName,
      },
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    if #cards > 0 then
      player:addSkillBranchUseHistory(quxian.name, "discard", 1)
      room:throwCard(cards, quxian.name, player, player)
      data.nullified = true
    else
      player:addSkillBranchUseHistory(quxian.name, "prey", 1)
      local card = room:getCardsFromPileByRule(data.card.trueName)
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, quxian.name, nil, false, player)
      end
    end
  end,
})

return quxian
