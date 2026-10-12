local shiao = fk.CreateSkill {
  name = "shiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shiao"] = "恃傲",
  [":shiao"] = "锁定技，当你的非装备牌进入弃牌堆后，若此牌造成过伤害，本回合你摸牌时摸牌数+1；"..
    "若此牌因弃置进入弃牌堆，本回合你摸牌时摸牌数-1。",

  ["@shiao-turn"] = "恃傲",

  ["$shiao1"] = "高士不取圯下履，淮阴见我亦低眉！",
  ["$shiao2"] = "留侯何在？履来！履来！",
}

shiao:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shiao.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).type ~= Card.TypeEquip and
                (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
                event:setCostData(self, { anim_type = "negative" })
                return true
              end
            end
          elseif move.from == nil and move.moveReason == fk.ReasonUse then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).type ~= Card.TypeEquip then
                local parent_event = player.room.logic:getCurrentEvent().parent
                if parent_event and parent_event.event == GameEvent.UseCard then
                  local use = parent_event.data
                  if use.from == player and use.damageDealt then
                    event:setCostData(self, { anim_type = "support" })
                    return true
                  end
                end
                return false
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self).anim_type == "support" then
      player.room:setPlayerMark(player, "@shiao-turn", player:getMark("@shiao-turn") + 1)
    else
      player.room:setPlayerMark(player, "@shiao-turn", player:getMark("@shiao-turn") - 1)
    end
  end,
})

shiao:addEffect(fk.BeforeDrawCard, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@shiao-turn") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { anim_type = (player:getMark("@shiao-turn") > 0 and "drawcard" or "negative") })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + player:getMark("@shiao-turn")
    if data.num <= 0 then
      return true
    end
  end,
})

return shiao
