local huangzhu = fk.CreateSkill {
  name = "os__huangzhu",
}

Fk:loadTranslationTable{
  ["os__huangzhu"] = "煌烛",
  [":os__huangzhu"] = "准备阶段，你可以选择一个已被废除的装备栏，从牌堆或弃牌堆中随机获得一张对应副类别的装备牌"..
  "（若无则随机获得一张装备牌），并记录此牌牌名。<br>"..
  "出牌阶段开始时，你可以选择或变更至多两个已记录且对应装备栏已被废除的装备牌牌名（每种副类别限一个），"..
  "视为拥有这些装备牌的技能直到此装备栏被恢复。",

  ["#os__huangzhu-choice"] = "煌烛：选择一个已废除的装备栏，获得一张此副类别的装备牌",
  ["@$os__huangzhu"] = "煌烛",
  ["#os__huangzhu-invoke"] = "煌烛：你可以选择或变更至多两个已记录的装备牌名，视为拥有其技能",
  ["#os__huangzhu"] = "煌烛：选择或变更至多两个已记录的装备牌名，视为拥有其技能",

  ["@os__huangzhu_WeaponSlot"] = "",
  ["@os__huangzhu_ArmorSlot"] = "",
  ["@os__huangzhu_DefensiveRideSlot"] = "",
  ["@os__huangzhu_OffensiveRideSlot"] = "",
  ["@os__huangzhu_TreasureSlot"] = "",
  ["@@os__huangzhu_sel_old"] = "已拥有",

  ["$os__huangzhu1"] = "赤心所愿，只愿天下清明！",
  ["$os__huangzhu2"] = "魏室初兴，长夜终尽。",
}

huangzhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(huangzhu.name) and target == player then
      if player.phase == Player.Start then
        return table.find(player.equipSlots, function (slot)
          return table.contains(player.sealedSlots, slot)
        end)
      elseif player.phase == Player.Play then
        return #player:getTableMark("@$os__huangzhu") > 0 and
          table.find(player.equipSlots, function (slot)
            return table.contains(player.sealedSlots, slot)
          end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local all_choices = {
        "WeaponSlot",
        "ArmorSlot",
        "DefensiveRideSlot",
        "OffensiveRideSlot",
        "TreasureSlot"
      }
      local choices = {}
      for i = 1, 5, 1 do
        if table.contains(player.sealedSlots, all_choices[i]) then
          table.insert(choices, all_choices[i])
        end
      end
      table.insert(all_choices, "Cancel")
      table.insert(choices, "Cancel")
      local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = huangzhu.name,
        prompt = "#os__huangzhu-choice",
        all_choices = all_choices,
      })
      if choice ~= "Cancel" then
        event:setCostData(self, {choice = choice})
        return true
      end
    elseif player.phase == Player.Play then -- 待优化
      local card_names = player:getTableMark("@$os__huangzhu")
      local all_slots = {
        "WeaponSlot",
        "ArmorSlot",
        "DefensiveRideSlot",
        "OffensiveRideSlot",
        "TreasureSlot"
      }
      local slots = player.sealedSlots
      table.sort(slots, function (a, b)
        return table.indexOf(all_slots, a) < table.indexOf(all_slots, b)
      end)
      local slot_card_map = {
        [Card.SubtypeWeapon] = {}, [Card.SubtypeArmor] = {}, [Card.SubtypeDefensiveRide] = {}, [Card.SubtypeOffensiveRide] = {}, [Card.SubtypeTreasure] = {}
      }
      local equipped = {}
      local can_change = false
      for _, name in ipairs(card_names) do
        local card = player:getMark("_os__huangzhu_cards")[name] --[[@as EquipCard]]
        if card then
          local slot = Util.convertSubtypeAndEquipSlot(card.sub_type)
          if table.contains(slots, slot) then
            local n = player:getMark("@os__huangzhu_" .. slot)
            local old = type(n) == "string" and n == card.name
            if old then
              -- room:addCardMark(card, "@@os__huangzhu_sel_old", 1) -- Poxi 看不见标记
              table.insert(equipped, card.id)
            else
              can_change = true
            end
            table.insert(slot_card_map[card.sub_type], card.id)
          end
        end
      end
      if can_change and player.room:askToSkillInvoke(player, {
        skill_name = huangzhu.name,
        prompt = "#os__huangzhu-invoke",
      }) then
        event:setCostData(self, {slots = slots, slot_card_map = slot_card_map, equipped = equipped})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local subtype_string_table = {
        [Player.ArmorSlot] = "armor",
        [Player.WeaponSlot] = "weapon",
        [Player.TreasureSlot] = "treasure",
        [Player.DefensiveRideSlot] = "defensive_ride",
        [Player.OffensiveRideSlot] = "offensive_ride",
      }
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|" .. subtype_string_table[event:getCostData(self).choice], 1, "allPiles")
      if #cards == 0 then
        cards = room:getCardsFromPileByRule(".|.|.|.|.|equip", 1, "allPiles")
      end
      if #cards == 0 then return false end
      local card = Fk:getCardById(room:tableRandomPick(cards))
      local card_names = player:getTableMark("@$os__huangzhu")
      if table.insertIfNeed(card_names, card.name) then
        local v_card = room:printCard(card.name, nil, nil)
        local record = player:getTableMark("_os__huangzhu_cards")
        record[card.name] = v_card
        room:setPlayerMark(player, "_os__huangzhu_cards", record)
        room:setPlayerMark(player, "@$os__huangzhu", card_names)
      end
      room:obtainCard(player, card, true, fk.ReasonJustMove, player, huangzhu.name)
    else -- 待优化
      local cost_data = event:getCostData(self)
      local slots = cost_data.slots
      local slot_card_map = cost_data.slot_card_map
      local equipped = cost_data.equipped
      local card_data = {}
      for _, slot in ipairs(slots) do
        local cards = slot_card_map[Util.convertSubtypeAndEquipSlot(slot)]
        if next(cards) then
          table.insert(card_data, {slot, cards})
        end
      end
      local res = room:askToPoxi(player, {
        poxi_type = "os__huangzhu",
        data = card_data,
        extra_data = { prohibit = equipped },
        cancelable = true,
      })
      if #res == 0 then return end
      for _, id in ipairs(res) do
        local card = Fk:getCardById(id) --[[@as EquipCard]]
        if card then
          local mark = "@os__huangzhu_" .. Util.convertSubtypeAndEquipSlot(card.sub_type)
          local record = player:getMark(mark)
          if record then
            room:setPlayerMark(player, mark, 0)
            local old_card = player:getMark("_os__huangzhu_cards")[record] --[[@as EquipCard]]
            if old_card then
              old_card:onUninstall(room, player)
            end
          end
          room:setPlayerMark(player, mark, card.name)
          card:onInstall(room, player)
        end
      end
    end
  end,
})

huangzhu:addEffect(fk.AreaResumed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(huangzhu.name, true) and player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, slot in ipairs(data.slots) do
      local name = player:getMark("@os__huangzhu_" .. slot)
      if type(name) == "string" then
        room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
        local card = player:getMark("_os__huangzhu_cards")[name] --[[@as EquipCard]]
        if card then
          card:onUninstall(room, player)
        end
      end
    end
  end,
})

huangzhu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if not is_death then return end
  room:setPlayerMark(player, "@$os__huangzhu", 0)
  room:setPlayerMark(player, "_os__huangzhu_cards", 0)
  local all_slots = {
    "WeaponSlot",
    "ArmorSlot",
    "DefensiveRideSlot",
    "OffensiveRideSlot",
    "TreasureSlot"
  }
  for _, slot in ipairs(all_slots) do
    local name = player:getMark("@os__huangzhu_" .. slot)
    if type(name) == "string" then
      room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
      local card = player:getMark("_os__huangzhu_cards")[name] --[[@as EquipCard]]
      if card then
        card:onUninstall(room, player)
      end
    end
  end
end)

Fk:addPoxiMethod{
  name = "os__huangzhu",
  prompt = "#os__huangzhu",
  card_filter = function(to_select, selected, data, extra_data)
    return #selected < 2 and (#selected == 0 or Fk:getCardById(selected[1]).sub_type ~= Fk:getCardById(to_select).sub_type) and not table.contains(extra_data.prohibit, to_select)
  end,
  feasible = Util.TrueFunc,
}

return huangzhu
