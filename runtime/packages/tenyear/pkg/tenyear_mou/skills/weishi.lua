local weishi = fk.CreateSkill {
  name = "weishi",
}

Fk:loadTranslationTable {
  ["weishi"] = "威势",
  [":weishi"] = "每回合每项限一次，1.你成为其他角色非伤害牌目标后，你可以弃置半数手牌（向上取整），令此牌对你无效；" ..
  "2.你成为其他角色伤害牌目标结算后，你可以摸两张牌，并可以对其使用一张【杀】。",

  ["#weishi-discard"] = "威势：你可以弃置%arg张手牌，令%arg2对你无效",
  ["#weishi-draw"] = "威势：是否摸两张牌并可以对 %dest 使用【杀】？",
  ["#weishi-slash"] = "威势：你可以对 %dest 使用【杀】",

  ["$weishi1"] = "豺狈虽众，其奈龙虎何？",
  ["$weishi2"] = "子敬！送关某一程山水如何！",
}

weishi:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weishi.name) and
        data.from ~= player and not data.card.is_damage_card and
        player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
        not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = (player:getHandcardNum() + 1) // 2
    local cards = room:askToDiscard(player, {
      skill_name = weishi.name,
      min_num = num,
      max_num = num,
      include_equip = false,
      cancelable = true,
      prompt = "#weishi-discard:::" .. num .. ":" .. data.card:toLogString(),
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.nullified = true
    player.room:throwCard(event:getCostData(self).cards, weishi.name, player, player)
  end,
})

weishi:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(weishi.name) and table.contains(data.tos, player) and
        data.card.is_damage_card and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = weishi.name,
      prompt = "#weishi-draw::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, weishi.name)
    if player.dead or target.dead then return end
    local use = room:askToUseCard(player, {
      skill_name = weishi.name,
      pattern = "slash",
      prompt = "#weishi-slash::" .. target.id,
      cancelable = true,
      extra_data = {
        exclusive_targets = { target.id },
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    end
  end,
})

return weishi
