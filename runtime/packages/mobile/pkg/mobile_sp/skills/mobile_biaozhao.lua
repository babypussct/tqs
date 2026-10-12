local mobileBiaozhao = fk.CreateSkill {
  name = "mobile__biaozhao",
  derived_piles = "$mobile__biaozhao_message",
}

Fk:loadTranslationTable{
  ["mobile__biaozhao"] = "表召",
  [":mobile__biaozhao"] = "结束阶段，你可以将一张牌扣置于武将牌上，称为“表”。当一张与“表”点数相同的牌进入弃牌堆时，" ..
  "你移去“表”并失去1点体力。准备阶段，你移去“表”，然后令一名角色回复1点体力并摸三张牌。",

  ["$mobile__biaozhao_message"] = "表",
  ["#mobile__biaozhao-cost"] = "表召：可以将一张牌作为表置于武将牌上",
  ["#mobile__biaozhao-choose"] = "表召：令一名角色回复1点体力并摸三张牌",

  ["$mobile__biaozhao1"] = "孙策如秦末之项籍，如得时势，必有异志！",
  ["$mobile__biaozhao2"] = "贡谨奉此表，以使君明孙策之异！",
}

mobileBiaozhao:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mobileBiaozhao.name) and
      (
        (player.phase == Player.Finish and not player:isNude()) or
        (player.phase == Player.Start and #player:getPile("$mobile__biaozhao_message") > 0)
      )
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      local cards = room:askToCards(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = mobileBiaozhao.name,
          prompt = "#mobile__biaozhao-cost",
        }
      )
      if #cards == 0 then
        return false
      end

      event:setCostData(self, {cards = cards})
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileBiaozhao.name
    local room = player.room
    if player.phase == Player.Finish then
      player:addToPile("$mobile__biaozhao_message", event:getCostData(self).cards, false, skillName)
    else
      room:moveCards({
        from = player,
        ids = player:getPile("$mobile__biaozhao_message"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = skillName,
      })
      local targets = room:askToChoosePlayers(
        player,
        {
          targets = room:getAlivePlayers(false),
          min_num = 1,
          max_num = 1,
          prompt = "#mobile__biaozhao-choose",
          skill_name = mobileBiaozhao.name,
          cancelable = false,
        }
      )
      if #targets > 0 then
        local to = targets[1]
        if to:isWounded() then
          room:recover{ who = to, num = 1, recoverBy = player, skillName = skillName }
        end
        if not to.dead then
          to:drawCards(3, skillName)
        end
      end
    end
  end,
})

mobileBiaozhao:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(mobileBiaozhao.name) or #player:getPile("$mobile__biaozhao_message") == 0 then return false end
    local numbers = {}
    for _, id in ipairs(player:getPile("$mobile__biaozhao_message")) do
      table.insertIfNeed(numbers, Fk:getCardById(id).number)
    end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if table.contains(numbers, card.number) then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileBiaozhao.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "negative")
    room:moveCards({
      from = player.id,
      ids = player:getPile("$mobile__biaozhao_message"),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = skillName,
    })
    if not player.dead then
      room:loseHp(player, 1, skillName)
    end
  end,
})

return mobileBiaozhao
