local huanghan = fk.CreateSkill{
  name = "huanghan",
}

Fk:loadTranslationTable{
  ["huanghan"] = "惶汗",
  [":huanghan"] = "当你受到牌造成的伤害后，你可以摸X张牌（X为此牌牌名字数）并弃置你已损失体力值张牌；若不为本回合首次发动，你视为未发动过〖保族〗。",

  ["#huanghan-invoke"] = "惶汗：你可以摸%arg张牌，弃置已损失体力值张牌",

  ["$huanghan1"] = "居天子阶下，故诚惶诚恐。",
  ["$huanghan2"] = "战战惶惶，汗出如浆。",
}

huanghan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huanghan.name) and data.card
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = huanghan.name,
      prompt = "#huanghan-invoke:::"..(math.floor(data.card:getNameLength(true))),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.card:getNameLength(true), huanghan.name)
    if not player.dead and player:isWounded() and not player:isNude() then
      local n = player:getLostHp()
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = huanghan.name,
        cancelable = false,
      })
    end
    if player:usedSkillTimes(huanghan.name, Player.HistoryTurn) > 1 and player:usedSkillTimes("baozu", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("baozu", 0, Player.HistoryGame)
    end
  end,
})

huanghan:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data
    local player = ai.player
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(player, data.card:getNameLength(true))
      local cards = table.filter(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end)
      ai:sortCards(cards, "keep_value")
      cards = table.slice(cards, 1, player:getLostHp() + 1)
      logic:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonDiscard, self.skill_name, nil, false, player)
      if player:usedSkillTimes(huanghan.name, Player.HistoryTurn) > 0 and
        player:usedSkillTimes("baozu", Player.HistoryGame) > 0 and player:hasSkill("baozu", true) then
        logic.benefit = logic.benefit + 200
      end
    end) > 0
  end,
})

return huanghan
