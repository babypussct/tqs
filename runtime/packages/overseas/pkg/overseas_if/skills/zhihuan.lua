local zhihuan = fk.CreateSkill {
  name = "os__zhihuan",
}

Fk:loadTranslationTable{
  ["os__zhihuan"] = "治宦",
  [":os__zhihuan"] = "①每个回合结束时，若你本回合失去过至少两种类型的牌，你可选择一项：1.获得当前回合角色装备区里的一张牌；" ..
  "2.获得并使用一张牌堆或弃牌堆中与你空置的装备栏对应类型的装备牌。②你的拼点牌点数+X（X为你已损失的体力值）。",

  ["os__zhihuan_prey"] = "获得%dest装备区一张牌",
  ["os__zhihuan_equip"] = "获得并使用一张装备",
  ["@@os__zhihuan_discard"] = "被治宦",

  ["$os__zhihuan1"] = "贪行祸国，谗言媚主，汝罪不容诛！",
  ["$os__zhihuan2"] = "阉宦小人，何以蔽天！",
}

zhihuan:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(zhihuan.name) then return end
    local types = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insertIfNeed(types, Fk:getCardById(info.cardId).type)
              if #types >= 2 then return true end
            end
          end
        end
      end
    end, Player.HistoryTurn)
    return #types >= 2 and (#target:getCardIds("e") > 0 or
      table.find(player:getAvailableEquipSlots(), function(s) return
        #player:getEquipments(Util.convertSubtypeAndEquipSlot(s)) < #player:getAvailableEquipSlots(Util.convertSubtypeAndEquipSlot(s))
      end))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {"os__zhihuan_prey::"..target.id, "os__zhihuan_equip"}
    if #target:getCardIds("e") == 0 then
      table.remove(choices, 1)
    end
    if not table.find(player:getAvailableEquipSlots(), function(s) return
        #player:getEquipments(Util.convertSubtypeAndEquipSlot(s)) < #player:getAvailableEquipSlots(Util.convertSubtypeAndEquipSlot(s))
      end) then
      table.remove(choices)
    end
    if #choices == 0 then return else table.insert(choices, "Cancel") end
    local choice =  room:askToChoice(player, {
      choices = choices,
      skill_name = zhihuan.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = {target}, choice = choice })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("os__zhihuan_prey") then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "e",
        skill_name = zhihuan.name,
      })
      room:obtainCard(player, card, true, fk.ReasonPrey, player, zhihuan.name)
    else
      local subtype_string_table = {
        [Card.SubtypeArmor] = "armor",
        [Card.SubtypeWeapon] = "weapon",
        [Card.SubtypeTreasure] = "treasure",
        [Card.SubtypeDelayedTrick] = "delayed_trick",
        [Card.SubtypeDefensiveRide] = "defensive_ride",
        [Card.SubtypeOffensiveRide] = "offensive_ride",
      }
      local slots = table.simpleClone(player:getAvailableEquipSlots())
      table.shuffle(slots)
      for _, slot in ipairs(slots) do
        if player.dead then return end
        local type = Util.convertSubtypeAndEquipSlot(slot)
        if #player:getEquipments(type) < #player:getAvailableEquipSlots(type) then
          local ids = room:getCardsFromPileByRule(".|.|.|.|.|"..subtype_string_table[type], 1, "allPiles")
          if #ids > 0 then
            local id = room:tableRandomPick(ids)
            room:obtainCard(player, id, true, fk.ReasonPrey, player, zhihuan.name)
            if not player.dead and table.contains(player:getCardIds("h"), id) and
              player:canUseTo(Fk:getCardById(id), player) then
              room:useCard{
                from = player,
                tos = {player},
                card = Fk:getCardById(id),
              }
            end
            break
          end
        end
      end
    end
  end,
})

zhihuan:addEffect(fk.PindianCardsDisplayed, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhihuan.name) and (player == data.from or data.results[player]) and player:getLostHp() > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:changePindianNumber(data, player, player:getLostHp(), zhihuan.name)
  end,
})

return zhihuan
