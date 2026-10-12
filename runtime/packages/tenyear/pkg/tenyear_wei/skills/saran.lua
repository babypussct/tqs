local saran = fk.CreateSkill {
  name = "saran",
}

Fk:loadTranslationTable{
  ["saran"] = "飒然",
  [":saran"] = "你的装备区每有一张牌，你出牌阶段使用【杀】次数+1。"..
  "你受到或造成1点伤害后，从牌堆或弃牌堆中随机使用一张装备牌（优先使用空置装备栏对应类别的牌），若有废除的装备栏可以先选择一个装备栏恢复。",

  ["#saran-choice"] = "飒然：是否要恢复一个装备栏？",

  ["$saran1"] = "愈创愈狂愈烈，越伤越战越凶！",
  ["$saran2"] = "阵前女儿怒，一步一杀一雷霆！",
}

---@param player ServerPlayer
local saranUse = function(_, _, _, player, _)
  local room = player.room
  local skillName = saran.name

  local all_slots = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
  local choices = {}
  for _, equip_slot in ipairs(all_slots) do
    if table.contains(player.sealedSlots, equip_slot) then
      table.insert(choices, equip_slot)
    end
  end
  if #choices > 0 then
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skillName,
      prompt = "#saran-choice",
    })
    if choice ~= "Cancel" then
      room:resumePlayerArea(player, {choice})
      if player.dead then return end
    end
  end

  -- 定义所有装备牌子类型：武器、防具、防御马、进攻马、宝物
  local equipSubtypes = {
    Card.SubtypeWeapon,
    Card.SubtypeArmor,
    Card.SubtypeDefensiveRide,
    Card.SubtypeOffensiveRide,
    Card.SubtypeTreasure
  }

  -- 【集合结构】用于 O(1) 快速判断：该装备类型是否有空装备栏（比 table.contains 快数倍）
  local validEquipTypeSet = {}

  -- 遍历所有装备类型，筛选出【有空位、可以装备】的类型
  for _, subtype in ipairs(equipSubtypes) do
    -- 获取当前类型的可用装备槽数量 / 已装备数量
    -- 规则：有可用槽位 + 槽位未装满 → 视为可装备
    if #player:getAvailableEquipSlots(subtype) > #player:getEquipments(subtype) then
      validEquipTypeSet[subtype] = true
    end
  end

  -- 定义两个结果表：
  -- targetCards：符合“有空装备栏”的装备牌（优先使用）
  -- fallbackCards：所有玩家可合法使用的装备牌（兜底使用）
  local targetCards = {}
  local fallbackCards = {}

  -- 【性能优化】不使用 table.connect 拼接大表，避免内存拷贝，直接分别遍历牌堆与弃牌堆
  local function processCardList(cardList)
    for _, cardId in ipairs(cardList) do
      local card = Fk:getCardById(cardId)
      -- 只处理玩家可以对自己使用的牌
      if card.type == Card.TypeEquip and player:canUseTo(card, player) then
        table.insert(fallbackCards, cardId)
        -- 如果该牌类型属于“有空装备栏”，加入优先列表
        if validEquipTypeSet[card.sub_type] then
          table.insert(targetCards, cardId)
        end
      end
    end
  end

  -- 处理牌堆 + 弃牌堆
  processCardList(room.draw_pile)
  processCardList(room.discard_pile)

  -- 选择使用列表：优先选有空位的目标牌，无则使用所有合法装备兜底
  local useCardList = next(targetCards) and targetCards or fallbackCards

  -- 列表为空则直接退出
  if not next(useCardList) then
    return
  end

  -- 随机选取一张装备，并对自己使用
  room:useCard{
    from = player,
    tos = { player },
    card = Fk:getCardById(room:tableRandomPick(useCardList)),
  }
end

saran:addEffect(fk.Damage, {
  anim_type = "offensive",
  trigger_times = function(_, _, _, _, data)
    return data.damage
  end,
  on_cost = Util.TrueFunc,
  on_use = saranUse,
})

saran:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(_, _, _, _, data)
    return data.damage
  end,
  on_cost = Util.TrueFunc,
  on_use = saranUse,
})

saran:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:hasShownSkill(self) and scope == Player.HistoryPhase then
      return #player:getCardIds("e")
    end
  end,
})

return saran
