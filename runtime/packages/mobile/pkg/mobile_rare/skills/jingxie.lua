local jingxie = fk.CreateSkill {
  name = "jingxie",
}

Fk:loadTranslationTable{
  ["jingxie"] = "精械",
  [":jingxie"] = "出牌阶段，你可以展示你手牌区或装备区里的一张【诸葛连弩】【八卦阵】【仁王盾】【白银狮子】【藤甲】，然后升级此牌；<br>"..
  "当你进入濒死状态时，你可以重铸一张防具牌，然后将体力值回复至1点。",

  ["#jingxie"] = "精械：你可以展示一张防具牌，将之升级",
  ["#jingxie-recast"] = "精械：你可以重铸一张防具牌，然后回复至1点体力",

  ["$jingxie1"] = "军具精巧，方保无虞。",
  ["$jingxie2"] = "巧则巧矣，未尽善也。",
}

jingxie:addEffect("active", {
  anim_type = "support",
  prompt = "#jingxie",
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and
      table.contains({ "crossbow", "eight_diagram", "nioh_shield", "silver_lion", "vine" }, Fk:getCardById(to_select).name)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:getCardById(effect.cards[1])
    local ex_card = room:printCard("ex_" .. card.name, card.suit, card.number)
    room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove, jingxie.name, nil, true, player)
    if not player.dead then
      room:obtainCard(player, ex_card.id, true)
    end
  end,
})

jingxie:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingxie.name) and player.dying and
      (not player:isKongcheng() or #player:getEquipments(Card.SubtypeArmor) > 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jingxie.name,
      pattern = ".|.|.|.|.|armor",
      prompt = "#jingxie-recast",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recastCard(event:getCostData(self).cards, player, jingxie.name)
    if player.hp < 1 and not player.dead then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = jingxie.name,
      }
    end
  end,
})

jingxie:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local cards = ai:getEnabledCards()
    if #cards > 0 then
      return { { cards[1] } }, ai:getBenefitOfEvents(function(logic)
        logic.benefit = logic.benefit + 200
      end)
    end
  end,
})

return jingxie
