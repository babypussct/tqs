local osTuidao = fk.CreateSkill {
  name = "os__tuidao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__tuidao"] = "颓盗",
  [":os__tuidao"] = "限定技，准备阶段，若“随征”角色体力值不大于2或已死亡，你可废除你与其的一个坐骑栏位，然后选择一个类别的牌，" ..
  "获得其所有该类别的牌（若其已死亡，则改为从牌堆中获得两张指定类别的牌），然后选择另一名其他角色作为新的“随征”角色，并令其获得这些牌。",

  ["#os__tuidao-ask2"] = "颓盗：你可废除你的一个坐骑栏，从牌堆中获得两张指定类别的牌，选择另一名角色作为新的“随征”角色",
  ["#os__tuidao-ask"] = "颓盗：你可废除你与 %dest 的一个坐骑栏，获得其所有指定类别的牌，选择另一名角色作为新的“随征”角色",
  ["#os__tuidao-card2"] = "颓盗：选择一个牌的类别，从牌堆中获得两张该类别的牌",
  ["#os__tuidao-card"] = "颓盗：选择一个牌的类别，获得 %dest 所有该类别的牌",
  ["#os__tuidao-new"] = "颓盗：选择一个新的“随征”角色，令其获得刚刚撸到的牌",

  ["$os__tuidao1"] = "将军大势已去，续无可奈何啊。",
  ["$os__tuidao2"] = "续投明主，还望将军勿怪才是。",
}

osTuidao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if
      target ~= player or
      player.phase ~= Player.Start or
      not player:hasSkill(osTuidao.name) or
      player:getMark("_os__suizheng") == 0 or
      player:usedSkillTimes(osTuidao.name, Player.HistoryGame) > 0
    then
      return false
    end

    local to = player.room:getPlayerById(player:getMark("_os__suizheng"))
    if not (to.hp <= 2 or to.dead) then
      return false
    end

    return
      (
        #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 and
        #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0
      ) or
      (
        #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0 and
        #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0
      )
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = { "DefensiveRideSlot", "OffensiveRideSlot", "Cancel" }
    local choices = { "DefensiveRideSlot", "OffensiveRideSlot" }
    local to = player.room:getPlayerById(player:getMark("_os__suizheng"))
    local dead = not to:isAlive()
    if
      #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0 or
      (not dead and #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0)
    then
      table.remove(choices)
    end
    if
      #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0 or
      (not dead and #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0)
    then
      table.remove(choices, 1)
    end

    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osTuidao.name,
        prompt = dead and "#os__tuidao-ask2" or "#os__tuidao-ask::" .. to.id,
        all_choices = all_choices,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osTuidao.name
    local choice = event:getCostData(self)
    local room = player.room
    local to = room:getPlayerById(player:getMark("_os__suizheng"))
    local slot = choice == "OffensiveRideSlot" and Player.OffensiveRideSlot or Player.DefensiveRideSlot
    room:abortPlayerArea(player, { slot })
    local dead = not to:isAlive()
    if not dead then room:abortPlayerArea(to, { slot }) end
    local choices = { "basic", "trick", "equip" }
    choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = skillName,
        prompt = dead and "#os__tuidao-card2" or "#os__tuidao-card::" .. to.id
      }
    )
    local cards = dead and
      room:getCardsFromPileByRule(".|.|.|.|.|" .. choice, 2) or
      table.filter(to:getCardIds("he"), function(id) return Fk:getCardById(id):getTypeString() == choice end)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, skillName)
    end

    local targets = table.filter(room.alive_players, function(p) return p ~= player and p ~= to end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__tuidao-new",
        skill_name = skillName,
        cancelable = false,
      }
    )

    local newTarget = tos[1]
    room:setPlayerMark(player, "_os__suizheng", newTarget.id)
    room:setPlayerMark(player, "@os__suizheng", newTarget.general)
    if #cards > 0 then
      cards = table.filter(cards, function(id)
        return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, newTarget, fk.ReasonPrey, skillName, nil, false, player)
      end
    end
  end,
})

return osTuidao
