local osGuimen = fk.CreateSkill {
  name = "os__guimen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__guimen"] = "鬼门",
  [":os__guimen"] = "锁定技，当你因弃置而失去♠牌后，你判定：若结果点数与你弃置的其中一张♠牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。",

  ["#os__guimen-target"] = "鬼门：对一名其他角色造成2点雷电伤害",
}

osGuimen:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osGuimen.name) then
      return false
    end

    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.suit == Card.Spade and card.number > 0 then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osGuimen.name
    local room = player.room
    local cardNumbers = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.suit == Card.Spade and card.number > 0 then
            table.insertIfNeed(cardNumbers, card.number)
          end
        end
      end
    end

    local tempNumbers = table.simpleClone(cardNumbers)
    for _, number in ipairs(tempNumbers) do
      table.insertTableIfNeed(cardNumbers, { number - 1, number + 1 })
    end
    local judge = {
      who = player,
      reason = skillName,
      pattern = ".|" .. table.concat(cardNumbers, ","),
    }
    room:judge(judge)
    if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    if judge:matchPattern() then
      local to = room:askToChoosePlayers(
        player,
        {
          targets = room:getOtherPlayers(player, false),
          min_num = 1,
          max_num = 1,
          prompt = "#os__guimen-target",
          skill_name = skillName,
          cancelable = false,
        }
      )[1]
      room:damage{
        from = player,
        to = to,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = skillName,
      }
    end
  end,
})

return osGuimen
