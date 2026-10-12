local chiguo = fk.CreateSkill {
  name = "chiguo",
}

Fk:loadTranslationTable{
  ["chiguo"] = "持国",
  [":chiguo"] = "出牌阶段开始时，你可以观看牌堆底三张牌。若如此做，本阶段当你使用一张牌时，亮出牌堆底牌，若这两张牌："..
  "花色相同，你为使用的牌增加或减少一个目标（目标数至少为一）；不同，你将亮出的牌交给其中一名目标角色。",

  ["#chiguo-choose"] = "持国：请为%arg增加或减少一个目标",
  ["#chiguo-give"] = "持国：将%arg交给其中一名目标角色",

  ["$chiguo1"] = "国之兴亡，匹夫有责，况吾等尚食君禄。",
  ["$chiguo2"] = "益州疲弊，非忠志之士不可持之。",
}

chiguo:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chiguo.name) and player.phase == Player.Play
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "chiguo-phase", 1)
    room:viewCards(player, {
      cards = room:getNCards(3, "bottom"),
      skill_name = chiguo.name,
    })
  end,
})

chiguo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chiguo.name) and player:getMark("chiguo-phase") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:getNCards(1, "bottom")
    room:turnOverCardsFromDrawPile(player, card, chiguo.name, true)
    if data.card:compareSuitWith(Fk:getCardById(card[1])) then
      local targets = data:getExtraTargets()
      if #data.tos > 1 then
        table.insertTableIfNeed(targets, data.tos)
      end
      if #targets > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#chiguo-choose:::"..data.card:toLogString(),
          skill_name = chiguo.name,
          cancelable = false,
          extra_data = table.map(data.tos, Util.IdMapper),
          target_tip_name = "addandcanceltarget_tip",
        })
        if #tos > 0 then
          local to = tos[1]
          if table.contains(data.tos, to) then
            data:removeTarget(to)
          else
            data:addTarget(to)
          end
        end
      end
    else
      local targets = table.filter(room.alive_players, function (p)
        return table.contains(data.tos, p)
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = chiguo.name,
          prompt = "#chiguo-give:::"..Fk:getCardById(card[1]):toLogString(),
          cancelable = false,
        })[1]
        room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, chiguo.name, nil, true, player)
      end
    end
    room:cleanProcessingArea(card)
  end,
})

return chiguo
