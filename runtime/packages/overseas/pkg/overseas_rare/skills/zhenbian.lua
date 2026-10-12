local zhenbian = fk.CreateSkill {
  name = "os__zhenbian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__zhenbian"] = "镇边",
  [":os__zhenbian"] = "锁定技，你的手牌上限等同于你的体力上限；当有牌不因使用而进入弃牌堆时，本技能记录这些牌的花色，" ..
  "然后若本技能记录了四种花色且你的体力上限小于8，则你清除记录的花色，加1点体力上限并摸一张牌。",

  ["@os__zhenbian"] = "镇边",

  ["$os__zhenbian1"] = "有吾在此，胡人何虑。",
  ["$os__zhenbian2"] = "某功甚大，当有此赏。",
}

zhenbian:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  priority = 2,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenbian.name) then
      for _, move in ipairs(data) do
        if (move.moveReason ~= fk.ReasonUse or not player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)) and
          move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = player:getTableMark("@os__zhenbian")
    for _, move in ipairs(data) do
      if (move.moveReason ~= fk.ReasonUse or not player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)) and
        move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
        end
      end
    end
    table.removeOne(suits, "log_nosuit")
    if #suits > 3 and player.maxHp < 8 then
      room:setPlayerMark(player, "@os__zhenbian", 0)
      room:changeMaxHp(player, 1)
      if not player.dead then
        player:drawCards(1, zhenbian.name)
      end
    else
      room:setPlayerMark(player, "@os__zhenbian", suits)
    end
  end,
})

zhenbian:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(zhenbian.name) then
      return player.maxHp
    end
  end
})

return zhenbian
