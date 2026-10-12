local fuzai = fk.CreateSkill {
  name = "fuzai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuzai"] = "覆载",
  [":fuzai"] = "锁定技，你不能使用装备牌且只能将你的装备牌当【借刀杀人】或【无中生有】使用；若你的装备区里没有牌，" ..
  "则你视为装备着一张<a href='#FuzaiVirtualEquipmentDesc'>随机的武器牌和防具牌</a>。",

  ["#FuzaiVirtualEquipmentDesc"] = "游戏开始或当你的体力变化后进行一次随机，武器牌须为攻击范围等同于你的体力值，" ..
  "防具牌须为牌名字数等同于你的体力值，无法满足则完全随机。<br/>" ..
  "随机池为标准+军争的武器和防具，以及【七宝刀】、【百辟刀】、【刑天破军斧】。",

  ["#fuzai-viewas"] = "覆载：你的装备牌只能当【借刀杀人】或【无中生有】使用",
  ["@[:]fuzai_weapon-noclear"] = "覆载",
  ["@[:]fuzai_armor-noclear"] = "覆载",

  ["$fuzai1"] = "舍去慈悲苦，目中唯蕴帝王志！",
  ["$fuzai2"] = "葬尽衣冠柩，魔气聚化绣龙袍。",
  ["$fuzai3"] = "万化归一，开以阴阳，持以纯相。",
  ["$fuzai4"] = "天子剑在心，何凭刀兵胄甲。",
  ["$fuzai5"] = "凡俗兵刃，何胆与神器争锋？",
}

fuzai:addEffect("viewas", {
  anim_type = "control",
  prompt = "#fuzai-viewas",
  pattern = "collateral,ex_nihilo",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|equip",
  },
  interaction_helper = function(self, player, selected_cards)
    local all_names = { "collateral", "ex_nihilo" }
    local names = player:getViewAsCardNames(fuzai.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil or #cards ~= 1 then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, fuzai.name, cards)
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

fuzai:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasSkill(fuzai.name) and card and card.type == Card.TypeEquip
  end,
})

local equipmentsPool = {
  { weapon = { "crossbow" } },
  { weapon = { "ice_sword", "qinggang_sword", "double_swords", "guding_blade" }, armor = { "vine" } },
  { weapon = { "axe", "blade", "spear" }, armor = { "eight_diagram", "nioh_shield" } },
  { weapon = { "halberd", "fan" }, armor = { "silver_lion" } },
  { weapon = { "kylin_bow" } },
}

local fuzaiEquipResume = function(player, flag)
  flag = flag or "weapon|armor"
  local room = player.room
  local toAcquire = {}
  local weapon = player:getMark("fuzai_weapon-noclear")
  if weapon ~= 0 and flag:find("weapon") then
    table.insert(toAcquire, Fk:cloneCard(weapon).equip_skill.name)
    room:setPlayerMark(player, "@[:]fuzai_weapon-noclear", weapon)
    room:setPlayerMark(player, "fuzai_weapon-noclear", 0)
  end

  local armor = player:getMark("fuzai_armor-noclear")
  if armor ~= 0 and flag:find("armor") then
    table.insert(toAcquire, Fk:cloneCard(armor).equip_skill.name)
    room:setPlayerMark(player, "@[:]fuzai_armor-noclear", armor)
    room:setPlayerMark(player, "fuzai_armor-noclear", 0)
  end

  if #toAcquire > 0 then
    room:handleAddLoseSkills(player, table.concat(toAcquire, "|"), fuzai.name, false, false)
  end
end

local fuzaiEquipRemove = function(player, flag, hide)
  flag = flag or "weapon|armor"
  hide = hide or true
  local room = player.room
  local toLose = {}
  local weapon = player:getMark("@[:]fuzai_weapon-noclear")
  if weapon ~= 0 and flag:find("weapon") then
    table.insert(toLose, Fk:cloneCard(weapon).equip_skill.name)
    room:setPlayerMark(player, "@[:]fuzai_weapon-noclear", 0)
    if hide then
      room:setPlayerMark(player, "fuzai_weapon-noclear", weapon)
    end
  end

  local armor = player:getMark("@[:]fuzai_armor-noclear")
  if armor ~= 0 and flag:find("armor") then
    table.insert(toLose, Fk:cloneCard(armor).equip_skill.name)
    room:setPlayerMark(player, "@[:]fuzai_armor-noclear", 0)
    if hide then
      room:setPlayerMark(player, "fuzai_armor-noclear", armor)
    end
  end

  if #toLose > 0 then
    room:handleAddLoseSkills(player, "-" .. table.concat(toLose, "|-"), fuzai.name, false, false)
  end
end

local fuzaiChangeEquipmentOnUse = function(self, event, target, player, data)
  fuzaiEquipRemove(player)

  local room = player.room
  local index = player.hp
  local toAcquire = {}

  local weapon
  if (index == 2 or index == 4 or index < 1 or index > #equipmentsPool) and math.random(1, 100) <= 10 then
    local specialWeapon = { "seven_stars_sword", "baipi_blade", "xingtian_axe" }
    if index == 2 then
      weapon = specialWeapon[math.random(1, 2)]
    elseif index == 4 then
      weapon = specialWeapon[3]
    else
      weapon = room:tableRandomPick(specialWeapon)
    end
  elseif index < 1 or index > #equipmentsPool then
    index = math.random(1, #equipmentsPool)
  end

  weapon = weapon or room:tableRandomPick(equipmentsPool[index].weapon)
  if #player:getCardIds("e") == 0 and player:hasEmptyEquipSlot(Card.SubtypeWeapon) then
    room:setPlayerMark(player, "@[:]fuzai_weapon-noclear", weapon)
    table.insert(toAcquire, Fk:cloneCard(weapon).equip_skill.name)
  else
    room:setPlayerMark(player, "fuzai_weapon-noclear", weapon)
  end

  index = player.hp
  local armor
  if index < 2 or index > 4 then
    index = math.random(2, 4)
  end

  armor = room:tableRandomPick(equipmentsPool[index].armor)
  if #player:getCardIds("e") == 0 and player:hasEmptyEquipSlot(Card.SubtypeArmor) then
    room:setPlayerMark(player, "@[:]fuzai_armor-noclear", armor)
    table.insert(toAcquire, Fk:cloneCard(armor).equip_skill.name)
  else
    room:setPlayerMark(player, "fuzai_armor-noclear", armor)
  end

  if #toAcquire > 0 then
    room:handleAddLoseSkills(player, table.concat(toAcquire, "|"), fuzai.name, false, false)
  end
end

fuzai:addEffect(fk.GameStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(fuzai.name, true, true) and #player:getCardIds("e") == 0
  end,
  on_refresh = fuzaiChangeEquipmentOnUse,
})

fuzai:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(fuzai.name, true, true) and
      #player:getCardIds("e") == 0 and
      data.num ~= 0
  end,
  on_refresh = fuzaiChangeEquipmentOnUse,
})

fuzai:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(fuzai.name, true, true) and
      table.find(data, function(move)
        if move.to == player and move.toArea == Card.PlayerEquip and #player:getCardIds("e") > 0 then
          return true
        end

        if move.from == player and #player:getCardIds("e") == 0 then
          return table.find(move.moveInfo, function(info)
            return info.fromArea == Card.PlayerEquip
          end) ~= nil
        end
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    if #player:getCardIds("e") > 0 then
      fuzaiEquipRemove(player)
    else
      fuzaiEquipResume(player)
    end
  end,
})

fuzai:addEffect(fk.AreaAborted, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(fuzai.name, true, true) and
      table.find(data.slots, function(slot)
        return
          (slot == Player.WeaponSlot and not player:hasEmptyEquipSlot(Card.SubtypeWeapon)) or
          (slot == Player.ArmorSlot and not player:hasEmptyEquipSlot(Card.SubtypeArmor))
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    if not player:hasEmptyEquipSlot(Card.SubtypeWeapon) then
      fuzaiEquipRemove(player, "weapon")
    end

    if not player:hasEmptyEquipSlot(Card.SubtypeArmor) then
      fuzaiEquipRemove(player, "armor")
    end
  end,
})

fuzai:addEffect(fk.AreaResumed, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(fuzai.name, true, true) and
      table.find(data.slots, function(slot)
        return
          (slot == Player.WeaponSlot and player:hasEmptyEquipSlot(Card.SubtypeWeapon)) or
          (slot == Player.ArmorSlot and player:hasEmptyEquipSlot(Card.SubtypeArmor))
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    if player:hasEmptyEquipSlot(Card.SubtypeWeapon) then
      fuzaiEquipResume(player, "weapon")
    end

    if player:hasEmptyEquipSlot(Card.SubtypeArmor) then
      fuzaiEquipResume(player, "armor")
    end
  end,
})

fuzai:addEffect("atkrange", {
  virtual_weapon_func = function(self, player)
    local weapon = player:getMark("@[:]fuzai_weapon-noclear")
    if player:hasSkill(fuzai.name) and weapon ~= 0 then
      local weaponAtkRange = Fk:cloneCard(weapon).attack_range
      return weaponAtkRange
    end
  end,
})

fuzai:addEffect("invalidity", {
  recheck_invalidity = true,
  invalidity_func = function(self, from, skill)
    if from:hasSkill(fuzai.name) or not skill:isEquipmentSkill(from) then
      return false
    end

    local weapon = from:getMark("@[:]fuzai_weapon-noclear")
    if weapon ~= 0 and Fk:cloneCard(weapon).equip_skill.name == skill.name then
      return true
    end

    local armor = from:getMark("@[:]fuzai_armor-noclear")
    if armor ~= 0 and Fk:cloneCard(armor).equip_skill.name == skill.name then
      return true
    end
  end,
})

fuzai:addAcquireEffect(function(self, player, isStart)
  if not isStart then
    fuzaiChangeEquipmentOnUse(nil, nil, nil, player)
  end
end)

fuzai:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    fuzaiEquipRemove(player, "weapon|armor", false)
  end
end)

return fuzai
