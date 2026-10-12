local zhujis = fk.CreateSkill {
  name = "zhujis",
}

Fk:loadTranslationTable{
  ["zhujis"] = "筑墼",
  [":zhujis"] = "出牌阶段结束时，你可以选择一张手牌，弃置与之花色相同的所有手牌，然后获得并使用牌堆中一张该花色的装备牌。"..
  "若你弃置的牌数不小于你使用此装备前装备区的牌数，你选择一项：1.摸两张牌；2.回复1点体力；3.获得1点护甲。",

  ["#zhujis-invoke"] = "筑墼：你可以弃置一种花色的手牌，获得并使用牌堆中一张该花色的装备牌",
  ["#zhujis-use"] = "筑墼：请使用%arg",
  ["zhujis_shield"] = "获得1点护甲",

  ["$zhujis1"] = "有此金汤之固，何惧远征之敌。",
  ["$zhujis2"] = "甲坚兵利，敌军自是难攻。",
  ["$zhujis3"] = "起楼橹，修器备，以御敌寇。",
  ["$zhujis4"] = "若无城甲之坚，何以拒敌于外。",
}

zhujis:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhujis.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhujis.name,
      prompt = "#zhujis-invoke",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = Fk:getCardById(event:getCostData(self).cards[1]).suit
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(Fk:getCardById(id)) and Fk:getCardById(id).suit == suit
    end)
    local yes = #cards >= #player:getCardIds("e")
    room:throwCard(cards, zhujis.name, player, player)
    if player.dead then return end
    cards = table.filter(room.draw_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and card.suit == suit and player:canUse(card)
    end)
    if #cards > 0 then
      local id = room:tableRandomPick(cards)
      room:obtainCard(player, id, true, fk.ReasonJustMove, player, zhujis.name)
      if player.dead then return end
      local card = Fk:getCardById(id)
      if table.contains(player:getCardIds("h"), id) and card.type == Card.TypeEquip and player:canUse(card) then
        if player:canUseTo(card, player) then
          room:useCard({
            from = player,
            tos = {player},
            card = card,
          })
        else
          room:askToUseRealCard(player, {
            pattern = {id},
            skill_name = zhujis.name,
            prompt = "#zhujis-use:::"..card:toLogString(),
            cancelable = false,
          })
        end
        if player.dead then return end
      end
    end

    if yes then
      local all_choices = {"draw2", "recover", "zhujis_shield"}
      local choices = table.simpleClone(all_choices)
      if not player:isWounded() then
        table.removeOne(choices, "recover")
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhujis.name,
        all_choices = all_choices,
      })
      if choice == "draw2" then
        player:drawCards(2, zhujis.name)
      elseif choice == "recover" then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhujis.name,
        }
      elseif choice == "zhujis_shield" then
        room:changeShield(player, 1)
      end
    end
  end,
})

return zhujis
