local yingjia = fk.CreateSkill{
  name = "os__yingjia",
}

Fk:loadTranslationTable{
  ["os__yingjia"] = "迎驾",
  [":os__yingjia"] = "一名角色的回合结束时，若你于此回合内使用过至少两张同名锦囊牌，你可以弃置一张手牌，令一名角色执行一个额外回合。",

  ["#os__yingjia-choose"] = "迎驾：弃置一张手牌，令一名角色获得一个额外回合",

  ["$os__yingjia1"] = "行非常之事，乃有非常之功，愿将军三思。",
  ["$os__yingjia2"] = "将军今留匡弼，事势不便，惟移驾幸许耳。",
}

yingjia:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yingjia.name) and not player:isKongcheng() then
      local names = {}
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == player and use.card.type == Card.TypeTrick then
          local name = use.card.trueName
          if table.contains(names, name) then
            return true
          else
            table.insert(names, name)
          end
        end
      end, Player.HistoryTurn) == 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      pattern = ".|.|.|hand",
      skill_name = yingjia.name,
      prompt = "#os__yingjia-choose",
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards == 1 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, yingjia.name, player, player)
    if not to.dead then
      to:gainAnExtraTurn(true, yingjia.name)
    end
  end,
})

return yingjia
