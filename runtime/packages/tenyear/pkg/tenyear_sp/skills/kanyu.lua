local kanyu = fk.CreateSkill {
  name = "kanyu",
}

Fk:loadTranslationTable{
  ["kanyu"] = "堪舆",
  [":kanyu"] = "当一名角色进行判定时或当你受到伤害时，你可以观看牌堆顶和牌堆底各一张牌，然后可以获得其中任意张牌并将其余牌以任意顺序置于牌堆顶。" ..
  "若你因此获得牌，本局游戏【闪电】对你生效的范围增加获得牌的花色点数。",

  ["@[kanyu]-noclear"] = "堪舆",
  ["#kanyu-split"] = "堪舆：你可分配其中的牌",

  ["$kanyu1"] = "肉食者生居黎庶之上，死亦独据黄泉乎！",
  ["$kanyu2"] = "王侯空拥灵宝而眠，我当取而告之。",
}

Fk:addPoxiMethod{
  name = "kanyu",
  card_filter = Util.TrueFunc,
  feasible = function(selected, data, extra_data)
    ---@cast data integer[][]
    ---@cast extra_data integer[][]
    if data[3][1] == extra_data[2][1] then
      return false
    end

    return true
  end,
}

local kanyuOnUse = function (self, event, target, player, data)
  ---@type string
  local skillName = kanyu.name
  local room = player.room

  local topCard = room:getNCards(1)
  local bottomCard = room:getNCards(1, "bottom")
  room:turnOverCardsFromDrawPile(player, { topCard[1], bottomCard[1] }, skillName, false)

  local result = room:askToArrangeCards(
    player,
    {
      skill_name = skillName,
      card_map = {
        {}, topCard, bottomCard,
        "prey", "Top", "Bottom"
      },
      prompt = "#kanyu-split",
      box_size = 0,
      max_limit = { 2, 2, 1 },
      min_limit = { 0, 0, 0 },
      poxi_type = "kanyu",
      default_choice = { {}, topCard, bottomCard },
    }
  )

  local toObtain, top, bottom = result[1], result[2], result[3]
  if #toObtain > 0 then
    local suits = {}
    local numbers = {}
    for _, id in ipairs(toObtain) do
      local card = Fk:getCardById(id)
      table.insert(suits, card:getSuitString())
      table.insert(numbers, card.number)
    end
    room:obtainCard(player, toObtain, false, fk.ReasonPrey, player, skillName)
    local patternMap = player:getTableMark("@[kanyu]-noclear")
    for i = 1, #toObtain do
      patternMap[suits[i]] = patternMap[suits[i]] or {}
      table.insertIfNeed(patternMap[suits[i]], numbers[i])
    end

    room:setPlayerMark(player, "@[kanyu]-noclear", patternMap)
  end

  if #top > 0 then
    room:returnCardsToDrawPile(player, top, skillName, "top", false)
  end
  if #bottom > 0 then
    room:returnCardsToDrawPile(player, bottom, skillName, "bottom", false)
  end
end

kanyu:addEffect(fk.StartJudge, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kanyu.name)
  end,
  on_use = kanyuOnUse,
})

kanyu:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kanyu.name)
  end,
  on_use = kanyuOnUse,
})

kanyu:addEffect(fk.FinishRetrial, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@[kanyu]-noclear") ~= 0 and data.reason == "lightning"
  end,
  on_refresh = function(self, event, target, player, data)
    local pattern = { ["else"] = "bad" }
    for suit, numbers in pairs(player:getTableMark("@[kanyu]-noclear")) do
      local patternStr = tostring(Exppattern{ suit = { suit }, number = numbers })
      pattern[patternStr] = "good"
    end

    data.pattern = pattern
  end,
})

Fk:addQmlMark{
  name = "kanyu",
  qml = {
    url = "packages/tenyear/qml/KanYuBox.qml",
  },
  how_to_show = function(name, value, p)
    return " "
  end,
}

kanyu:addAcquireEffect(function(self, player)
  if player:getMark("@[kanyu]-noclear") == 0 then
    local baseNumbers = {}
    for i = 2, 9 do
      table.insert(baseNumbers, i)
    end
    player.room:setPlayerMark(player, "@[kanyu]-noclear", { ["spade"] = baseNumbers })
  end
end)

kanyu:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return kanyu
