local zhiyi = fk.CreateSkill {
  name = "zhiyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhiyi"] = "执义",
  [":zhiyi"] = "锁定技，一名角色的结束阶段，若你本回合使用或打出过基本牌，你选择一项：1.视为使用任意一张你本回合使用或打出过的基本牌；2.摸一张牌。",
  ["#zhiyi-use"] = "执义：视为使用一张基本牌，或点“取消”摸一张牌",

  ["$zhiyi1"] = "岂可擅退而误国家之功？",
  ["$zhiyi2"] = "统摄不懈，只为破敌！",
}

zhiyi:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(zhiyi.name) and
      (
        #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          return use.from == player and use.card.type == Card.TypeBasic
        end, Player.HistoryTurn) > 0 or
        #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
          local use = e.data
          return use.from == player and use.card.type == Card.TypeBasic
        end, Player.HistoryTurn) > 0
      )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhiyi.name
    local room = player.room
    if player:getMark("zhiyi_cards") == 0 then
      room:setPlayerMark(player, "zhiyi_cards", room:getUniversalCards("b"))
    end

    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryTurn)
    room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryTurn)

    local cards = table.filter(player:getMark("zhiyi_cards"), function (id)
      return table.contains(names, Fk:getCardById(id).name)
    end)
    local use = room:askToUseRealCard(
      player,
      {
        pattern = cards,
        skill_name = skillName,
        prompt = "#zhiyi-use",
        extra_data = { expand_pile = cards, bypass_times = true },
        skip = true,
      }
    )

    if use then
      local card = Fk:cloneCard(use.card.name)
      card.skillName = skillName
      use = {
        from = player,
        tos = use.tos,
        card = card,
        extraUse = true,
      }
      room:useCard(use)
    else
      player:drawCards(1, skillName)
    end
  end,
})

return zhiyi
