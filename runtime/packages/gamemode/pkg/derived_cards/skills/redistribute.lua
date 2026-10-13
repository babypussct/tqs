local skill = fk.CreateSkill {
  name = "redistribute_skill",
}

Fk:loadTranslationTable{
  ["redistribute_skill"] = "调剂盐梅",
  [":redistribute_skill"] = "选择两名手牌数不同的角色，手牌数小的角色摸一张牌，其余弃置一张手牌。<br/>"..
  "然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色",
  ["#redistribute-give"] = "你可将因【调剂盐梅】弃置的牌交给一名角色",
  ["#redistribute_skill"] = "选择两名手牌数不同的角色，手牌数小的角色摸一张牌，其余弃置一张手牌。<br/>"..
    "然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色",
}

skill:addEffect("cardskill", {
  prompt = "#redistribute_skill",
  target_num = 2,
  mod_target_filter = Util.TrueFunc,
  target_filter = function(self, player, to_select, selected, _, card, _)
    if player:isProhibited(to_select, card) then return end
    return #selected ~= 1 or to_select:getHandcardNum() ~= selected[1]:getHandcardNum()
  end,
  on_use = function(self, room, cardUseEvent)
    if cardUseEvent.tos and #cardUseEvent:getAllTargets() > 0 then
      cardUseEvent.extra_data = cardUseEvent.extra_data or {}
      local num, minPlayers = 9998, {}
      for _, p in ipairs(cardUseEvent:getAllTargets()) do
        local hand_num = p:getHandcardNum()
        if num > hand_num then
          num = hand_num
          minPlayers = {p.id}
        elseif num == hand_num then
          table.insert(minPlayers, p.id)
        end
      end
      if #cardUseEvent:getAllTargets() == #minPlayers then minPlayers = {} end
      if #minPlayers > 0 then cardUseEvent.extra_data.redistributeMinPlayer = minPlayers end
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local to = cardEffectEvent.to
    if table.contains(((cardEffectEvent.extra_data or {}).redistributeMinPlayer or {}), to.id) then
      to:drawCards(1, "redistribute")
    elseif not to:isKongcheng() then
      local cids = room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = "redistribute",
        cancelable = false,
      })
      if #cids > 0 then
        cardEffectEvent.extra_data.redistributeCids = cardEffectEvent.extra_data.redistributeCids or {}
        table.insert(cardEffectEvent.extra_data.redistributeCids, cids[1])
      end
    end
  end,
  on_action = function(self, room, use, finished)
    if finished and (use.extra_data or {}).redistributeCids and not use.from.dead then
      if use.tos and #use:getAllTargets() > 0 then
        local num = nil
        for _, p in ipairs(use:getAllTargets()) do
          local hand_num = p:getHandcardNum()
          if num == nil then
            num = hand_num
          elseif num ~= hand_num then
            use.extra_data.redistributeCids = nil
            return false
          end
        end
      end
      local cids = table.filter(use.extra_data.redistributeCids, function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cids == 0 then
        use.extra_data.redistributeCids = nil
        return false
      end
      local target = room:askToChoosePlayers(use.from, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        skill_name = "redistribute",
        prompt = "#redistribute-give",
        cancelable = true,
      })
      if #target > 0 then room:moveCardTo(cids, Player.Hand, target[1], fk.ReasonGive, "redistribute") end
      use.extra_data.redistributeCids = nil
    end
  end,
})

skill:addTest(function (room, me)
  local comp2, comp3 = room.players[2], room.players[3]
  local card = room:printCard("redistribute")
  FkTest.setNextReplies(me, { FkTest.replyCard(card, {comp2, comp3}), FkTest.replyChoosePlayer{comp3} })
  FkTest.runInRoom(function ()
    room:obtainCard(me, card)
    comp2:drawCards(2)
    me:gainAnExtraPhase(Player.Play)
  end)
end)

return skill
