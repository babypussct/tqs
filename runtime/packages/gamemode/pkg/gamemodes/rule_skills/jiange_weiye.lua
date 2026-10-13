local weiye = fk.CreateSkill {
  name = "jiange__weiye",
}

Fk:loadTranslationTable{
  ["jiange__weiye"] = "魏业",
  [":jiange__weiye"] = "准备阶段，你可以弃置一张牌，令一名敌方角色选择一项：1.弃置一张牌；2.你摸一张牌。",

  ["#jiange__weiye-invoke"] = "魏业：你可以弃置一张牌，令一名敌方角色选择弃置一张牌或令你摸一张牌",
  ["#jiange__weiye-discard"] = "魏业：弃置一张牌，否则 %src 摸一张牌",
}

weiye:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      not player:isNude() and #player:getEnemies() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = weiye.name,
      prompt = "#jiange__weiye-invoke",
      cancelable = true,
      will_throw = true,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, {tos = to, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, weiye.name, player, player)
    if to.dead then return end
    if player.dead then
      room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = weiye.name,
        cancelable = false,
      })
    else
      if #room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = weiye.name,
        cancelable = true,
        prompt = "#jiange__weiye-discard:"..player.id,
      }) == 0 then
        player:drawCards(1, weiye.name)
      end
    end
  end,
})

return weiye
