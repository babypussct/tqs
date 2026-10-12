local dianlun = fk.CreateSkill {
  name = "dianlun",
}

Fk:loadTranslationTable {
  ["dianlun"] = "典论",
  [":dianlun"] = "出牌阶段限一次，你可以弃置任意张点数之差相同的手牌，然后摸等量的牌，这些牌本回合不受〖肃纲〗限制且无距离次数限制。",

  ["#dianlun"] = "典论：弃置任意张点数之差相同的手牌，摸等量的牌",
  ["#dianlun_update"] = "典论：弃置任意张点数之差相同的手牌，摸两倍的牌",
  ["@@dianlun-inhand-turn"] = "典论",

  ["$dianlun1"] = "寄身翰墨，见意篇籍，规此身以华章！",
  ["$dianlun2"] = "行文论七子，建安有贤，千秋之幸。",
}

dianlun:addEffect("active", {
  anim_type = "drawcard",
  prompt = function(self, player, selected_cards, selected_targets)
    if player:getMark("dianlun_update-turn") > 0 then
      return "#dianlun_update"
    else
      return "#dianlun"
    end
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(dianlun.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) and
        Fk:getCardById(to_select).number > 0 then
      if #selected < 2 then
        return true
      else
        if player:getMark("dianlun_limited") > 0 and #selected == 3 then return end
        local nums = table.map(selected, function(id)
          return Fk:getCardById(id).number
        end)
        table.insert(nums, Fk:getCardById(to_select).number)
        table.sort(nums)
        for i = 2, #nums - 1 do
          if nums[i + 1] - nums[i] ~= nums[i] - nums[i - 1] then
            return false
          end
        end
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, dianlun.name, player, player)
    if player.dead then return end
    player:drawCards(#effect.cards * (player:getMark("dianlun_update-turn") > 0 and 2 or 1),
      dianlun.name, nil, "@@dianlun-inhand-turn")
  end,
})

dianlun:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:hasMark("@@dianlun-inhand-turn")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end
})

dianlun:addEffect("targetmod", {
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and card:getMark("@@dianlun-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill_name, card)
    return card and card:getMark("@@dianlun-inhand-turn") > 0
  end,
})

return dianlun
