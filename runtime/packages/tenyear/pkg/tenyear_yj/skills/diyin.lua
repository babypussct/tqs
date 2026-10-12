local diyin = fk.CreateSkill {
  name = "diyin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["diyin"] = "笛音",
  [":diyin"] = "锁定技，你每失去七次牌后，你获得下一次进入弃牌堆的牌；当你受到伤害后，所有体力与你相同的角色各摸一张牌。",

  ["@diyin"] = "笛音",

  ["$diyin1"] = "五声十二律，一管纳乾坤。",
  ["$diyin2"] = "昆山采蓝玉，裂石穿云，不若此间笛响。",
}

diyin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(diyin.name) and player:getMark("@diyin") > 6 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and #move.moveInfo > 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@diyin", 0)
    local ids = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    ids = table.filter(ids, function (id)
      return table.contains(player.room.discard_pile, id)
    end)
    ids = player.room.logic:moveCardsHoldingAreaCheck(ids)
    if #ids > 0 then
      room:obtainCard(player, ids, false, fk.ReasonJustMove, player, diyin.name)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(diyin.name)
  end,
  on_refresh = function(self, event, target, player, data)
    -- 获取当前印记层数，满6层直接退出（最多存7层）
    local curMark = player:getMark("@diyin")
    local x = curMark
    if x > 6 then return end

    local room = player.room
    -- 本轮移动内，手牌、装备是否已经计数过（同轮只各加1层）
    local flag = { hand = false, equip = false }

    -- 遍历本次所有卡牌移动记录
    for _, move in ipairs(data) do
      -- 提前满层直接跳出所有循环，优化性能
      if x > 6 then break end
      -- 只处理：卡牌从自己身上移走的记录
      if move.from ~= player then goto continue_move end

      -- 判定本次移动是否需要计入印记
      local needCount = true
      if move.moveReason == fk.ReasonUse then
        -- 移动原因是【使用牌】，需要额外判断父事件
        local curEvent = player.room.logic:getCurrentEvent()
        local parentEvent = curEvent and curEvent.parent or nil
        if parentEvent and parentEvent.event == GameEvent.UseCard then
          local useData = parentEvent.data
          -- 条件：自己装备装备牌时，不计层
          if useData.from == player and useData.card and useData.card.type == Card.TypeEquip then
            needCount = false
          end
        end
      end

      -- 不需要计数直接跳过本条move
      if not needCount then goto continue_move end

      -- 遍历本条移动内所有卡牌明细
      for _, info in ipairs(move.moveInfo) do
        if x > 6 then break end
        -- 手牌流失，且本轮未计过手牌层
        if not flag.hand and info.fromArea == Card.PlayerHand and
          (move.to ~= player or move.toArea ~= Card.PlayerHand) then
          flag.hand = true
          x = x + 1
        -- 装备区流失，且本轮未计过装备层
        elseif not flag.equip and info.fromArea == Card.PlayerEquip  and
          (move.to ~= player or move.toArea ~= Card.PlayerEquip) then
          flag.equip = true
          x = x + 1
        end
      end

      ::continue_move::
    end

    -- 层数上涨则更新标记，封顶7
    if x > curMark then
      room:setPlayerMark(player, "@diyin", math.min(x, 7))
    end
  end
})

diyin:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = table.filter(player.room.alive_players, function(p)
      return p.hp == player.hp
    end)
    room:sortByAction(tos, player)
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(1, diyin.name)
      end
    end
  end
})

diyin:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@diyin", 0)
end)

return diyin