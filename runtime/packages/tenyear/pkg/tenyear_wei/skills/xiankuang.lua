local xiankuang = fk.CreateSkill {
  name = "xiankuang",
}

Fk:loadTranslationTable{
  ["xiankuang"] = "贤贶",
  [":xiankuang"] = "有角色非因使用失去基本牌进入弃牌堆时，你可以废除一个装备栏并选择一项："..
  "1.获得此牌；2.令此角色摸你废除的装备栏数张牌（一回合因此技能获得牌累计大于一张时，此技能本回合失效）。",

  ["#xiankuang-choice"] = "贤贶：是否废除一个装备栏？",
  ["xiankuang_getcard"] = "获得一张弃牌",
  ["xiankuang_draw_to"] = "令%dest摸%arg张牌",
  ["xiankuang_draw"] = "令失去牌的角色摸%arg张牌",
  ["#xiankuang-card"] = "贤贶：选择一张弃牌获得",
  ["#xiankuang-draw"] = "贤贶：选择一名失去牌的角色，令其摸%arg张牌",

  ["$xiankuang1"] = "陛下夜嬉到明，明嬉到夜，能乐死曹叡否？",
  ["$xiankuang2"] = "相父字字珠玑，奈何汝看在眼里、忘之脑后！",
}

--使用SkillData储存通用部分，避免多人发动或多次自选导致的大量重复工作
--注意不要进行任何动态信息的判断（比如角色状态、会改变的卡牌信息等）
---@type TrigFunc
local getXianKuangSkillData = function(self, event, target, player, data)
  local dat = event:getSkillData(self, self.name)
  if dat == nil then
    local room = player.room
    local cards, toResponse, toPindian, toConfirm = {}, {}, {}, {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              table.insert(cards, { info.cardId, move.from })
            end
          end
        else
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing then
              if move.moveReason == fk.ReasonResponse then
                table.insert(toResponse, info.cardId)
              elseif move.moveReason == fk.ReasonPindian then
                table.insert(toPindian, info.cardId)
              elseif move.moveReason ~= fk.ReasonUse then
                table.insert(toConfirm, info.cardId)
              end
            end
          end
        end
      end
    end
    if #toResponse > 0 then
      local move_event = room.logic:getCurrentEvent()
      local parent_event = move_event.parent
      if parent_event.event == GameEvent.RespondCard then
        local use = parent_event.data ---@type RespondCardData
        if use.subcardsFromInfo then
          for _, info in ipairs(use.subcardsFromInfo) do
            if table.removeOne(toResponse, info.cardId) and info.from == use.from then
              --使用木马里的牌也能发动，故不判fromArea
              table.insert(cards, { info.cardId, info.from })
            end
          end
        end
      end
    end
    if #toPindian > 0 then
      local move_event = room.logic:getCurrentEvent()
      local parent_event = move_event.parent
      if parent_event.event == GameEvent.Pindian then
        local pindian = parent_event.data ---@type PindianData
        for _, id in ipairs(room:getSubcardsByRule(pindian.fromCard)) do
          if table.removeOne(toPindian, id) then
            table.insert(cards, { id, pindian.from })
          end
        end
        for to, result in pairs(pindian.results) do
          for _, id in ipairs(room:getSubcardsByRule(result.toCard)) do
            if table.removeOne(toPindian, id) then
              table.insert(cards, { id, to })
            end
          end
        end
      end
    end
    if #toConfirm > 0 then
      local start_id = room.logic:getCurrentEvent().id
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
        if e.id < start_id then
          for _, move in ipairs(e.data) do
            for _, info in ipairs(move.moveInfo) do
              if table.removeOne(toConfirm, info.cardId) and
                (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
                table.insert(cards, { info.cardId, move.from })
              end
            end
          end
          return (#toConfirm == 0)
        end
      end, 0)
    end
    dat = cards
    event:setSkillData(self, self.name, dat)
  end
  return dat
end

xiankuang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(xiankuang.name) and #player:getAvailableEquipSlots() > 0 then
      local dat = getXianKuangSkillData(self, event, target, player, data)
      local discardPile = room.discard_pile
      --线上实测如果弃牌堆不存在弃置的牌则不能发动
      --线上实测如果目标角色死亡，可以废除装备栏但是没有后续效果
      if table.find(dat, function(id)
        return table.contains(discardPile, id[1]) and Fk:getCardById(id[1]).type == Card.TypeBasic
      end) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot"
    }
    local subtypes = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure
    }
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = xiankuang.name,
      prompt = "#xiankuang-choice",
      all_choices = all_choices,
      cancelable = true
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = xiankuang.name
    room:abortPlayerArea(player, { event:getCostData(self).choice })
    if player.dead then return end
    local x = #table.filter(player.sealedSlots, function(slot)
      return slot ~= Player.JudgeSlot
    end)
    local dat = event:getSkillData(self, self.name)
    local cards = {}
    local tos = {} ---@type ServerPlayer[]
    local discardPile = room.discard_pile
    --线上实测优先对原区域按获得牌的顺序的最后一张牌及对应的角色发动，拼点时优先对拼点目标发动，这里改成自选
    for _, value in ipairs(dat) do
      if Fk:getCardById(value[1]).type == Card.TypeBasic and table.contains(discardPile, value[1]) then
        table.insert(cards, value[1])
        if value[2]:isAlive() then
          table.insertIfNeed(tos, value[2])
        end
      end
    end
    local choices = {}
    if #cards > 0 then
      table.insert(choices, "xiankuang_getcard")
    end
    if #tos > 0 and x > 0 then
      if #tos == 1 then
        table.insert(choices, "xiankuang_draw_to::" .. tos[1].id .. ":" .. x)
      else
        table.insert(choices, "xiankuang_draw:::" .. x)
      end
    end
    if #choices == 0 then return end
    local choice = choices[1]
    if #choices > 1 then
      choice = room:askToChoice(player, {
        choices = choices,
        skill_name = skillName,
      })
    end
    if choice == "xiankuang_getcard" then
      local id = cards[1]
      if #cards > 1 then
        id = player.room:askToChooseCard(player, {
          target = player,
          flag = { card_data = { { skillName, cards } } },
          skill_name = skillName,
          prompt = "#xiankuang-card",
        })
      end
      room:obtainCard(player, id, false, fk.ReasonJustMove, player, skillName)
      if player:usedSkillTimes(xiankuang.name, Player.HistoryTurn) > 1 then
        room:invalidateSkill(player, skillName, "-turn")
      end
    else
      local to = tos[1]
      if #tos > 1 then
        to = room:askToChoosePlayers(player, {
          targets = tos,
          min_num = 1,
          max_num = 1,
          prompt = "#xiankuang-draw:::" .. x,
          skill_name = skillName,
          cancelable = false
        })[1]
      end
      to:drawCards(x, skillName)
      if x > 1 or player:usedSkillTimes(xiankuang.name, Player.HistoryTurn) > 1 then
        room:invalidateSkill(player, skillName, "-turn")
      end
    end
  end,
})

return xiankuang
