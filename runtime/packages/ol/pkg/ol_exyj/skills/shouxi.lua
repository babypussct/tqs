local shouxi = fk.CreateSkill {
  name = "ol_ex__shouxi",
}

Fk:loadTranslationTable{
  ["ol_ex__shouxi"] = "守玺",
  [":ol_ex__shouxi"] = "每回合限一次，当你成为伤害牌的目标后，你可以弃置包含伤害牌的任意张牌，对使用者造成1点伤害。"..
  "然后若此牌未对你造成伤害，你摸牌至手牌上限。",

  ["#ol_ex__shouxi-invoke"] = "守玺：你可以弃置包含伤害牌的任意张牌，对 %dest 造成1点伤害",

  ["$ol_ex__shouxi1"] = "皇天在上，必不佑尔佞臣贼子。",
  ["$ol_ex__shouxi2"] = "昔父执鞭以安天下，今兄何功得御九州？"
}

shouxi:addAuxActiveSkill("#ol_ex__shouxi_active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  feasible = function (self, player, selected, selected_cards, card)
    return table.find(selected_cards, function (id)
      return Fk:getCardById(id).is_damage_card
    end)
  end,
})

shouxi:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shouxi.name) and
      data.card.is_damage_card and not player:isKongcheng() and
      player:usedSkillTimes(shouxi.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#ol_ex__shouxi_active",
      prompt = "#ol_ex__shouxi-invoke::"..data.from.id,
    })
    if success and dat then
      event:setCostData(self, { tos = { data.from }, cards = dat.cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.ol_ex__shouxi = data.extra_data.ol_ex__shouxi or {}
    table.insertIfNeed(data.extra_data.ol_ex__shouxi, player)
    room:throwCard(event:getCostData(self).cards, shouxi.name, player, player)
    if not data.from or data.from.dead then return end
    room:damage{
      from = player,
      to = data.from,
      damage = 1,
      skillName = shouxi.name,
    }
  end
})

shouxi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not (data.damageDealt and data.damageDealt[player]) and
      player:getHandcardNum() < player:getMaxCards() and
      data.extra_data and data.extra_data.ol_ex__shouxi and table.contains(data.extra_data.ol_ex__shouxi, player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMaxCards() - player:getHandcardNum(), shouxi.name)
  end,
})

return shouxi
