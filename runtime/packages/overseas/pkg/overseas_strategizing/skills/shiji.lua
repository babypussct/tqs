local shiji = fk.CreateSkill {
  name = "os__shiji",
}

Fk:loadTranslationTable{
  ["os__shiji"] = "势击",
  [":os__shiji"] = "准备阶段，你从牌堆或弃牌堆中获得两张花色不同的牌，然后你可以弃置一张牌，"..
  "与弃置牌花色相同的牌于本回合内被展示后，你摸一张牌。你使用【火攻】造成伤害后，弃置对方【火攻】展示的牌。",

  ["#os__shiji-ask"] = "势击：你可以弃置一张牌，本回合展示此花色牌后你摸一张牌",
  ["@os__shiji-turn"] = "势击",

  ["$os__shiji1"] = "焚火鼓噪，便可一举灭敌。",
  ["$os__shiji2"] = "良机难觅，吾等万不可失。",
}

shiji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shiji.name) and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = { {}, {}, {}, {}, {} }
    for _, id in ipairs(table.connect(room.draw_pile, room.discard_pile)) do
      table.insert(cards[Fk:getCardById(id).suit], id)
    end
    local ids, index = {}, {}
    for i = 1, 4 do
      if #cards[i] > 0 then
        table.insert(index, i)
      end
    end
    index = room:tableRandomPick(index, 2)
    for _, i in ipairs(index) do
      table.insert(ids, room:tableRandomPick(cards[i]))
    end
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, shiji.name, nil, false, player)
    end
    if not player:isNude() then
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = shiji.name,
        cancelable = true,
        prompt = "#os__shiji-ask",
        skip = true,
      })
      if #card > 0 then
        room:addTableMarkIfNeed(player, "@os__shiji-turn", Fk:getCardById(card[1]):getSuitString(true))
        room:throwCard(card, shiji.name, player, player)
      end
    end
  end,
})

shiji:addEffect(fk.CardShown, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(shiji.name) and
      table.find(data.cardIds, function (id)
        return table.contains(player:getTableMark("@os__shiji-turn"), Fk:getCardById(id):getSuitString(true))
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, shiji.name)
  end,
})

shiji:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(shiji.name) and
      data.card and data.card.trueName == "fire_attack" then
      local effect_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      return effect_event and effect_event.data.extra_data.fire_attack_show and
        table.contains(data.to:getCardIds("h"), effect_event.data.extra_data.fire_attack_show[1])
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local effect_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if effect_event then
      local card = effect_event.data.extra_data.fire_attack_show
      room:throwCard(card, shiji.name, data.to, player)
    end
  end,
})

return shiji
