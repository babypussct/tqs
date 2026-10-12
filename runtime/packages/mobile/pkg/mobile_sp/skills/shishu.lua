local shishu = fk.CreateSkill {
  name = "shishu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shishu"] = "恃术",
  [":shishu"] = "锁定技，其他角色于其回合内获得你的牌后，你令其选择一项：1.弃置这些牌；2.交给你一张与这些牌类别均不相同的牌。",

  ["shishu_discard"] = "弃置这些牌",
  ["shishu_give"] = "交给其一张与这些牌类别均不同的牌",
  ["#shishu-give"] = "恃术：请选择其中一张牌交给 %dest",

  ["$shishu1"] = "达为形势所迫，实乃不得不行也。",
  ["$shishu2"] = "臣过奉教于君子，愿君王勉之也。",
}

shishu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shishu.name) then
      local current = player.room:getCurrent()
      if not (current and current ~= player and not current.dead) then return end
      for _, move in ipairs(data) do
        if move.from == player and move.to == current and
          (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = shishu.name
    local room = player.room
    local current = room:getCurrent()  ---@cast current ServerPlayer

    local choices = {}
    local cardsGiven = {}
    for _, move in ipairs(data) do
      if move.from == player and move.to == current and
        (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(cardsGiven, info.cardId)
          end
        end
      end
    end

    local types = {}
    for _, id in ipairs(cardsGiven) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
      if #types == 3 then
        break
      end
    end

    local toDiscard =  table.filter(cardsGiven, function(id)
      return
        room:getCardOwner(id) == current and
        table.contains({ Card.PlayerHand, Card.PlayerEquip }, room:getCardArea(id)) and
        not current:prohibitDiscard(Fk:getCardById(id))
    end)
    if #toDiscard > 0 then
      table.insert(choices, "shishu_discard")
    end

    if
      #types < 3 and
      table.find(current:getCardIds("he"), function(id)
        return not table.contains(types, Fk:getCardById(id):getTypeString())
      end)
    then
      table.insert(choices, "shishu_give")
    end

    if #choices == 0 then
      return false
    end

    local choice = room:askToChoice(
      current,
      {
        choices = choices,
        skill_name = skillName,
        all_choices = { "shishu_discard", "shishu_give" }
      }
    )

    if choice == "shishu_discard" then
      room:throwCard(toDiscard, skillName, current, current)
    else
      local ids = room:askToCards(
        current,
        {
          min_num = 1,
          max_num = 1,
          pattern = ".|.|.|.|.|^(" .. table.concat(types, ",") ..")",
          include_equip = true,
          skill_name = skillName,
          prompt = "#shishu-give::" .. player.id,
          cancelable = false,
        }
      )

      room:obtainCard(player, ids, false, fk.ReasonGive, current, skillName)
    end
  end,
})

return shishu
