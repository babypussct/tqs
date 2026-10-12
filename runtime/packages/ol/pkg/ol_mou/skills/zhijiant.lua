local zhijiant = fk.CreateSkill {
  name = "zhijiant",
}

Fk:loadTranslationTable{
  ["zhijiant"] = "执谏",
  [":zhijiant"] = "出牌阶段限一次，你可以摸3-X张牌并交给一名其他角色一张牌，此牌称为“谏”直到其下个回合结束。"..
  "然后若其使用的下一张牌不为“谏”，你可以再次对其发动此技能（X为此技能本回合此前已发动次数）。",

  ["#zhijiant"] = "执谏：你可以摸%arg张牌，交给一名其他角色一张牌",
  ["#zhijiant-invoke"] = "执谏：你可以摸%arg张牌，交给 %dest 一张牌",
  ["#zhijiant-give"] = "执谏：将一张牌作为“谏”交给一名其他角色",
  ["@@zhijiant-inhand"] = "谏",

  ["$zhijiant1"] = "",
  ["$zhijiant2"] = "",
}

zhijiant:addEffect("active", {
  anim_type = "support",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#zhijiant:::"..(3 - player:usedSkillTimes(zhijiant.name, Player.HistoryTurn))
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhijiant.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local target
    if #effect.tos > 0 then
      target = effect.tos[1]
    end
    player:drawCards(4 - player:usedSkillTimes(zhijiant.name, Player.HistoryTurn), zhijiant.name)
    if player:isNude() or #room:getOtherPlayers(player, false) == 0 then return end
    local targets = room:getOtherPlayers(player, false)
    if target and not target.dead then
      targets = { target }
    end
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = ".",
      skill_name = zhijiant.name,
      prompt = "#zhijiant-give",
      cancelable = false,
    })
    room:setPlayerMark(player, zhijiant.name, to[1])  --盲猜会覆盖
    room:moveCardTo(card, Card.PlayerHand, to[1], fk.ReasonGive, zhijiant.name, nil, false, player,
      { "@@zhijiant-inhand", player.id })
  end,
})

zhijiant:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(zhijiant.name) and
      table.contains((data.extra_data or {}).zhijiant or {}, player)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = zhijiant.name,
      prompt = "#zhijiant-invoke::" .. target.id .. ":" .. (3 - player:usedSkillTimes(zhijiant.name, Player.HistoryTurn)),
      cancelable = true,
      skip = true,
    })
    if success and dat then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    Fk.skills[zhijiant.name]:onUse(player.room, {
      from = player,
      tos = { target },
    })
  end,

  can_refresh = function (self, event, target, player, data)
    return player:getMark(zhijiant.name) == target
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, zhijiant.name, 0)
    if table.every(data:getMark("@@zhijiant-inhand"), function (mark)
      return mark ~= player.id
    end) then
      data.extra_data = data.extra_data or {}
      data.extra_data.zhijiant = data.extra_data.zhijiant or {}
      table.insertIfNeed(data.extra_data.zhijiant, player)
    end
  end,
})

zhijiant:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:clearHandMark(player, "@@zhijiant-inhand")
  end,
})

return zhijiant
