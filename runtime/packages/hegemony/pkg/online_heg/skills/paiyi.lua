local paiyi = fk.CreateSkill {
  name = "ol_heg__paiyi",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable{
  ["ol_heg__paiyi"] = "排异",
  [":ol_heg__paiyi"] = "主将技，你计算体力上限时减少1个单独的阴阳鱼。弃牌阶段结束时，若你此阶段未弃置牌，你可以将任意张“权”交给一名角色，"..
  "然后若其手牌数大于你，你对其造成1点伤害。",

  ["#ol_heg__paiyi-give"] = "排异：将任意张“权”交给一名角色，然后若其手牌数大于你则对其造成1点伤害",

  ["$ol_heg__paiyi1"] = "妨碍我的人，都得死！",
  ["$ol_heg__paiyi2"] = "此地容不下你！",
}

paiyi:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(paiyi.name) and player.phase == Player.Discard and
      #player:getPile("ol_heg__zhonghui_quan") > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            return true
          end
        end
      end, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = #player:getPile("ol_heg__zhonghui_quan"),
      targets = room.alive_players,
      skill_name = paiyi.name,
      pattern = ".|.|.|ol_heg__zhonghui_quan",
      prompt = "#ol_heg__paiyi-give",
      cancelable = true,
      expand_pile = "ol_heg__zhonghui_quan",
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, { tos = to, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards or {}
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, paiyi.name, nil, true, player)
    if not to.dead and to:getHandcardNum() > player:getHandcardNum() then
      room:damage {
        from = player,
        to = to,
        damage = 1,
        skillName = paiyi.name,
      }
    end
  end,
})

return paiyi
