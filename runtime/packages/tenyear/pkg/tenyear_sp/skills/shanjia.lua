local shanjia = fk.CreateSkill {
  name = "ty__shanjia",
}

Fk:loadTranslationTable{
  ["ty__shanjia"] = "缮甲",
  [":ty__shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（你每不因使用而失去过一张装备牌，便少弃置一张），若你本次没有弃置过："..
  "基本牌，你此阶段使用【杀】次数上限+1；锦囊牌，你此阶段使用牌无距离限制；都满足，你可以视为使用【杀】。",

  ["#ty__shanjia-slash"] = "缮甲：你可以视为使用【杀】",
  ["@ty__shanjia"] = "缮甲",

  ["$ty__shanjia1"] = "百锤锻甲，披之可陷靡阵、断神兵、破坚城！",
  ["$ty__shanjia2"] = "千炼成兵，邀天下群雄引颈，且试我剑利否！"
}

shanjia:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanjia.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, shanjia.name)
    if player.dead then return end
    local cards = {}
    if player:getMark("@ty__shanjia") > 0 then
      cards = room:askToDiscard(player, {
        min_num = player:getMark("@ty__shanjia"),
        max_num = player:getMark("@ty__shanjia"),
        include_equip = true,
        skill_name = shanjia.name,
        cancelable = false,
        skip = true,
      })
    end
    local flag1, flag2 = false, false
    if not table.find(cards, function(id)
      return Fk:getCardById(id).type == Card.TypeBasic
    end) then
      flag1 = true
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", 1)
    end
    if not table.find(cards, function(id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end) then
      flag2 = true
      room:addPlayerMark(player, MarkEnum.BypassDistancesLimit.."-turn", 1)
    end
    if #cards > 0 then
      room:throwCard(cards, shanjia.name, player, player)
    end
    if player.dead then return end
    if flag1 and flag2 then
      room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = shanjia.name,
        prompt = "#ty__shanjia-slash",
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
    end
  end,
})

shanjia:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@ty__shanjia") > 0 and player:hasSkill(shanjia.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player then
        if move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).type == Card.TypeEquip then
              n = n + 1
            end
          end
        else
          local parent_event = player.room.logic:getCurrentEvent().parent
          if parent_event ~= nil then
            if parent_event.event == GameEvent.UseCard then
              local use = parent_event.data
              if use.from == player and use.card.type ~= Card.TypeEquip then
                parent_event:searchEvents(GameEvent.MoveCards, 1, function(e2)
                  if e2.parent and e2.parent.id == parent_event.id then
                    for _, move2 in ipairs(e2.data) do
                      if move2.from == player and move2.moveReason == fk.ReasonUse then
                        for _, info in ipairs(move2.moveInfo) do
                          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId).type == Card.TypeEquip then
                            n = n + 1
                          end
                        end
                      end
                    end
                  end
                end)
              end
            end
          end
        end
      end
    end
    if n > 0 then
      player.room:removePlayerMark(player, "@ty__shanjia", n)
    end
  end,
})

shanjia:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@ty__shanjia", 3)
end)

shanjia:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ty__shanjia", 0)
end)

shanjia:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return shanjia
