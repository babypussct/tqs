local mingcha = fk.CreateSkill {
  name = "mingcha",
}

Fk:loadTranslationTable{
  ["mingcha"] = "明察",
  [":mingcha"] = "摸牌阶段开始时，你亮出牌堆顶三张牌，然后你可以放弃摸牌并获得其中点数不大于8的牌，" ..
  "若你以此法获得了牌，你可以选择一名其他角色，随机获得其一张牌。",

  ["#mingcha-get"] = "明察：是否放弃摸牌，获得其中点数不大于8的牌？",
  ["#mingcha-choose"] = "明察：你可以选择一名角色，随机获得其一张牌",

  ["$mingcha1"] = "明主可以理夺，怎可以情求之？",
  ["$mingcha2"] = "祸见于此，何免之有？",
}

mingcha:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingcha.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mingcha.name
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      proposer = player,
    })
    room:delay(2000)

    local choice = room:askToViewCardsAndChoice(player, {
      cards = cards,
      choices = { "OK", "Cancel" },
      skill_name = skillName,
      prompt = "#mingcha-get"
    })
    if choice == "OK" then
      data.phase_end = true
      local to_get = {}
      for i = 3, 1, -1 do
        if Fk:getCardById(cards[i]).number < 9 then
          table.insert(to_get, cards[i])
          table.remove(cards, i)
        end
      end

      if #to_get > 0 then
        room:obtainCard(player, to_get, true, fk.ReasonPrey, player, skillName)

        if player:isAlive() then
          local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
          if #targets > 0 then
            local to = room:askToChoosePlayers(
              player,
              {
                targets = targets,
                min_num = 1,
                max_num = 1,
                prompt = "#mingcha-choose",
                skill_name = skillName,
              }
            )
            if #to > 0 then
              room:obtainCard(player, room:tableRandomPick(to[1]:getCardIds("he")), false, fk.ReasonPrey, player, skillName)
            end
          end
        end
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        fromArea = Card.Processing,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = skillName,
      })
    end
  end,
})

return mingcha
