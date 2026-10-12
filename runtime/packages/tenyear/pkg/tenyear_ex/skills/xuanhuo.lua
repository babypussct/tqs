local xuanhuo = fk.CreateSkill {
  name = "ty_ex__xuanhuo",
}

Fk:loadTranslationTable{
  ["ty_ex__xuanhuo"] = "眩惑",
  [":ty_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张手牌，并选择另一名其他角色，该角色选择一项：1.视为对后者使用"..
  "任意一种【杀】或【决斗】，2.交给你所有手牌。",

  ["#ty_ex__xuanhuo-invoke"] = "眩惑：选择两名角色，交给第一名角色两张手牌，其选择视为对第二名角色使用【杀】或【决斗】，或交给你所有手牌",
  ["#ty_ex__xuanhuo-use"] = "眩惑：视为对 %dest 使用【杀】或【决斗】，或点“取消”交给 %src 所有手牌",

  ["$ty_ex__xuanhuo1"] = "光以眩目，言以惑人。",
  ["$ty_ex__xuanhuo2"] = "我法孝直如何会害你？",
}

xuanhuo:addAuxActiveSkill("ty_ex__xuanhuo_active", {
  card_num = 2,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and #selected < 2
  end,
})

xuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhuo.name) and player.phase == Player.Draw and
      player:getHandcardNum() > 1 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__xuanhuo_active",
      prompt = "#ty_ex__xuanhuo-invoke",
      cancelable = true
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, xuanhuo.name, nil, false, player)
    if to.dead then return end
    local victim = event:getCostData(self).tos[2]
    if victim.dead then
      if not player.dead and not to:isKongcheng() then
        room:moveCardTo(to:getCardIds("h"), Card.PlayerHand, player, fk.ReasonGive, xuanhuo.name, nil, false, to)
        return
      end
    end
    local names = player:getMark(xuanhuo.name)
    if type(names) ~= "table" then
      names = { "slash" }
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.trueName == "slash" and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insert(names, "duel")
      room:setPlayerMark(player, xuanhuo.name, names)
    end
    local use = room:askToUseVirtualCard(to, {
      name = names,
      skill_name = xuanhuo.name,
      prompt = "#ty_ex__xuanhuo-use:"..player.id..":"..victim.id,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = { victim.id },
      },
      cancelable = true,
    })
    if use == nil then
      local cards = to:getCardIds("h")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, xuanhuo.name, nil, false, to)
      end
    end
  end,
})

return xuanhuo
