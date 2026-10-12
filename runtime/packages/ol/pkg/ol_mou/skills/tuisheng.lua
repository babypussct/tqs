local tuisheng = fk.CreateSkill{
  name = "tuisheng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["tuisheng"] = "蜕生",
  [":tuisheng"] = "限定技，准备阶段或当你进入濒死状态时，你可以重置你本局使用过的〖赂存〗牌名，"..
  "然后选择一项并回复1点体力：1.将所有手牌置为“赂”；2.你随机从弃牌堆中获得游戏轮数张重置前〖赂存〗使用牌名的牌。",

  ["tuisheng_push"] = "将你的所有手牌置为“赂”",
  ["tuisheng_prey"] = "随机获得〖赂存〗使用过的牌",

  ["$tuisheng1"] = "陛下明鉴，此王侯所为，吾等实不知。",
  ["$tuisheng2"] = "宫内污秽？敢问公卿以下忠清者为谁！",
  ["$tuisheng3"] = "奸臣胁国，当伏其罪，我等共图之。",
  ["$tuisheng4"] = "前个儿奉事我等的奴才，今儿就想要反主吗？！",
  ["$tuisheng5"] = "我等愿尽献家财，唯乞太后怜悯。",
  ["$tuisheng6"] = "众常侍如缚豕待宰，惟待大将军前来。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tuisheng_push", "tuisheng_prey", "Cancel" },
      skill_name = tuisheng.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local storedCardNames = player:getTableMark("lucun") or {}
    room:setPlayerMark(player, "lucun", {}) -- 每次发动清空记录

    local choice = event:getCostData(self).choice

    -- 固定效果：受伤则恢复1点体力
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tuisheng.name
      }
    end

    -- ==============================================
    -- 选项1：将所有手牌置入标记堆，并记录牌名
    -- ==============================================
    if choice == "tuisheng_push" then
      if not player:isKongcheng() then
        local handCards = player:getCardIds("h")
        player:addToPile("olmou__zhangrang_lu", handCards, true, tuisheng.name, player)

        -- 记录被推入的牌名，用于下次取回
        local cardNameList = {}
        for i = 1, #handCards do
          local card = Fk:getCardById(handCards[i])
          cardNameList[i] = card.name
        end
        room:setPlayerMark(player, "lucun", cardNameList)
      end

    -- ==============================================
    -- 选项2：从弃牌堆取回牌（高性能乱序 + 顺序抽取）
    -- ==============================================
    else
      local nameCount = #storedCardNames
      if nameCount == 0 then return end

      -- 目标获取数量 = 当前游戏轮数
      local targetDrawCount = room:getBanner("RoundCount") or 1
      if targetDrawCount <= 0 then return end

      -- 快速查询表：判断牌名是否需要收集
      local nameFilter = {}
      for i = 1, nameCount do
        nameFilter[storedCardNames[i]] = true
      end

      -- 遍历弃牌堆，构建【牌名 => 牌ID列表】映射表
      local cardMap = {}
      local discardPile = room.discard_pile
      for i = 1, #discardPile do
        local cardId = discardPile[i]
        local cardName = Fk:getCardById(cardId).trueName
        if nameFilter[cardName] then
          local cardList = cardMap[cardName] or {}
          cardMap[cardName] = cardList
          cardList[#cardList + 1] = cardId
        end
      end

      -- 对每个牌名列表洗牌（使用room的随机系列函数）
      for _, cardList in pairs(cardMap) do
        room:shuffleTable(cardList)
      end

      -- 按 storedCardNames 顺序循环取牌，不放回
      local resultCards = {}
      local currentGotCount = 0
      local pointer = 1

      while currentGotCount < targetDrawCount do
        local currentName = storedCardNames[pointer]
        local cardList = cardMap[currentName]

        -- 有牌就拿一张（尾部删除，O(1) 性能）
        if cardList and #cardList > 0 then
          currentGotCount = currentGotCount + 1
          resultCards[currentGotCount] = table.remove(cardList)
        end

        -- 拿满目标数量，立即退出
        if currentGotCount >= targetDrawCount then
          break
        end

        -- 指针循环：A→B→C→A→B…
        pointer = pointer % nameCount + 1

        -- 检查所有牌是否已拿空
        local allPileEmpty = true
        for i = 1, nameCount do
          local list = cardMap[storedCardNames[i]]
          if list and #list > 0 then
            allPileEmpty = false
            break
          end
        end
        if allPileEmpty then break end
      end

      -- 将获得的牌交给玩家
      if currentGotCount > 0 then
        room:moveCardTo(resultCards, Card.PlayerHand, player, fk.ReasonJustMove, tuisheng.name, nil, false, player)
      end
    end
  end,
}

tuisheng:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and
      player:hasSkill(tuisheng.name) and player:usedSkillTimes(tuisheng.name, Player.HistoryGame) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

tuisheng:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.hp < 1 and
      player:hasSkill(tuisheng.name) and player:usedSkillTimes(tuisheng.name, Player.HistoryGame) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return tuisheng
