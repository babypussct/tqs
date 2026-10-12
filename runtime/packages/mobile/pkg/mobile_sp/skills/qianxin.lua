local qianxin = fk.CreateSkill{
  name = "mobile__qianxinz",
}

Fk:loadTranslationTable{
  ["mobile__qianxinz"] = "遣信",
  [":mobile__qianxinz"] = "出牌阶段限一次，你可以将至多两张手牌随机分配给等量名其他角色各一张，称为“信”，然后该角色的下个准备阶段，"..
  "若其有“信”，其选择一项：1.令你摸两张牌；2.本回合的手牌上限-2。",

  ["#mobile__qianxinz"] = "遣信：选择至多两张手牌，随机分配给等量名其他角色",
  ["@@mobile__mail-inhand"] = "信",
  ["mobile__qianxinz1"] = "%src 摸两张牌",
  ["mobile__qianxinz2"] = "你本回合手牌上限-2",

  ["$mobile__qianxinz1"] = "兵困绝地，将至如归！",
  ["$mobile__qianxinz2"] = "临危之际，速速来援！",
}

qianxin:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__qianxinz",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(qianxin.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select) and
      #selected < math.min(2, #table.filter(Fk:currentRoom().alive_players, function (p)
        return p ~= player
      end))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local tos = room:tableRandomPick(room:getOtherPlayers(player, false), #effect.cards)
    if #tos ~= #effect.cards then return end
    local moves = {}
    for i, p in ipairs(tos) do
      table.insert(moves, {
        from = player,
        to = p,
        ids = {effect.cards[i]},
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        skillName = qianxin.name,
        moveVisible = false,
        proposer = player,
        moveMark = {"@@mobile__mail-inhand", player.id},
      })
    end
    room:moveCards(table.unpack(moves))
  end,
})
qianxin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Start and target ~= player and
      table.find(target:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mobile__mail-inhand") == player.id
      end)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(target:getCardIds("h")) do
      if Fk:getCardById(id):getMark("@@mobile__mail-inhand") == player.id then
        room:setCardMark(Fk:getCardById(id), "@@mobile__mail-inhand", 0)
      end
    end
    if player.dead then return end
    local choice = room:askToChoice(target, {
      choices = {"mobile__qianxinz1:"..player.id, "mobile__qianxinz2"},
      skill_name = qianxin.name,
    })
    if choice ~= "mobile__qianxinz2" then
      player:drawCards(2, qianxin.name)
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
    end
  end,
})

return qianxin
