local zhuangshi = fk.CreateSkill {
  name = "zhuangshi",
}

Fk:loadTranslationTable{
  ["zhuangshi"] = "壮誓",
  [":zhuangshi"] = "出牌阶段开始时，你可以依次执行其中的任意项：1.弃置任意张手牌，你此阶段使用的前等量张牌无距离限制且不可响应；" ..
  "2.失去任意点体力，你此阶段使用的前等量张牌不计入次数。",

  ["#zhuangshi-discard"] = "壮誓：弃置任意张手牌，本阶段使用前等量张牌无距离限制且不可响应",
  ["#zhuangshi-loseHp"] = "壮誓：失去任意点体力，本阶段使用前等量张牌不计次数",
  ["@zhuangshi-phase"] = "壮誓",

  ["$zhuangshi1"] = "若魏寇将十万之众，延当为主公尽歼。	",
  ["$zhuangshi2"] = "纵曹贼举天下进犯，延亦可勠力拒退。",
}

zhuangshi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuangshi.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = zhuangshi.name
    local room = player.room

    local toDiscard = room:askToDiscard(player, {
      min_num = 1,
      max_num = player:getHandcardNum(),
      skill_name = skillName,
      prompt = "#zhuangshi-discard",
      skip = true,
    })

    local toLose
    if player.hp > 0 then
      toLose = room:askToNumber(player, {
        min = 1,
        max = player.hp,
        skill_name = skillName,
        cancelable = true,
        prompt = "#zhuangshi-loseHp",
      })
    end

    if #toDiscard > 0 or toLose then
      event:setCostData(self, { cards = toDiscard, hp = toLose })
    else
      event:setCostData(self, { cancelled = true })
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhuangshi.name
    local room = player.room

    local costData = event:getCostData(self) or Util.DummyTable
    if not costData.cancelled then
      if #(costData.cards or {}) > 0 or (costData.hp or 0) > 0 then
        room:setPlayerMark(player, "@zhuangshi-phase", { #costData.cards, costData.hp })
      end
      if #(costData.cards or {}) > 0 then
        room:throwCard(costData.cards, skillName, player, player)
      end
      if player.dead then return end
      if costData.hp then
        room:loseHp(player, costData.hp, skillName)
      end
    end
  end,
})

zhuangshi:addEffect(fk.PreCardUse, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@zhuangshi-phase") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@zhuangshi-phase")
    if #mark > 0 and mark[1] > 0 then
      mark[1] = mark[1] - 1
      data.disresponsiveList = room:getAllPlayers(false)
    end

    if #mark > 1 and mark[2] > 0 then
      mark[2] = mark[2] - 1
      data.extraUse = true
    end

    if table.every(mark, function(buff) return buff == 0 end) then
      mark = 0
    end

    room:setPlayerMark(player, "@zhuangshi-phase", mark)
  end,
})

zhuangshi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("@zhuangshi-phase") ~= 0 and
      player:getTableMark("@zhuangshi-phase")[1] > 0
  end,
})

zhuangshi:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@zhuangshi-phase", 0)
end)

zhuangshi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local slash = #table.filter(ai.player:getCardIds("h"), function (id)
      return Fk:getCardById(id).trueName == "slash" and
        ai.player:canUse(Fk:getCardById(id), { bypass_distances = true, bypass_times = true })
    end)
    if ai.data[4].skillName == self.skill_name then
      if ai.data[1] == "discard_skill" then
        if slash == 0 then
          local cards = ai:getEnabledCards()
          if #cards > 0 then
            ai:sortCards(cards, "keep_value")
            local benefit = ai:getBenefitOfEvents(function(logic)
              logic:throwCard(cards[1], self.skill_name, ai.player, ai.player)
            end)
            return { { cards[1] }, {} }, benefit
          else
            return { {}, {} }, 0
          end
          return
        end
        local cards = table.filter(ai:getEnabledCards(), function (id)
          return Fk:getCardById(id).trueName ~= "slash" and ai:getCardValue(id) <= 45
        end)
        if #cards == 0 then
          return { {}, {} }, 0
        end
        ai:sortCards(cards, "keep_value")
        local n = math.min(slash, #cards)
        cards = table.slice(cards, 1, n + 1)
        local benefit = ai:getBenefitOfEvents(function(logic)
          logic:throwCard(cards, self.skill_name, ai.player, ai.player)
          logic.benefit = logic.benefit + n * 100
        end)
        return { cards, {} }, benefit
      elseif ai.data[1] == "spin_skill" then
        if slash == 0 then return end
        local peach = false
        for _, p in ipairs(ai.player:getFriends()) do
          if p == ai.player then
            if table.find(p:getCardIds("h"), function (id)
              return table.contains({ "peach", "analeptic" }, Fk:getCardById(id).trueName) and
                not p:isProhibited(ai.player, Fk:getCardById(id))
            end) then
              peach = true
              break
            end
          else
            if table.find(p:getCardIds("h"), function (id)
              return Fk:getCardById(id).trueName == "peach" and
                not p:isProhibited(ai.player, Fk:getCardById(id))
            end) then
              peach = true
              break
            end
          end
        end
        local n = math.min(slash, ai.player.hp - (peach and 0 or 1))
        if n > 0 then
          return { nil, nil, n }, 100
        end
      end
    end
  end,
})

return zhuangshi
