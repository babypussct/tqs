local huazhang = fk.CreateSkill {
  name = "os__huazhang",
}

Fk:loadTranslationTable{
  ["os__huazhang"] = "华章",
  [":os__huazhang"] = "出牌阶段结束时，你可以重铸任意张手牌，若X不小于2，这些牌每满足一项：花色相同、点数连续、牌名相同，"..
  "你便依次执行一项：1.摸X张牌；2.本回合手牌上限+X；3.摸X张牌且本回合手牌上限+X（X为重铸的牌数）。",

  ["#os__huazhang-invoke"] = "你可发动“华章”，重铸任意张手牌",

  ["$os__huazhang1"] = "起承转合处，自有风云声。",
  ["$os__huazhang2"] = "文心蕴天地，笔落引凤鸣！",
  ["$os__huazhang3"] = "诸君且看，此篇之才，当值几斗？哈哈哈哈哈哈！",
}

huazhang:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huazhang.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = player:getHandcardNum(),
      cancelable = true,
      skill_name = huazhang.name,
      prompt = "#os__huazhang-invoke",
    })
    if #cards > 0 then
      local n = 0
      if #cards >= 2 then
        local first_card = Fk:getCardById(cards[1])
        if table.every(cards, function (id)
          return Fk:getCardById(id):compareSuitWith(first_card)
        end) then
          n = 1
        end
        local nums = table.map(cards, function (id)
          return Fk:getCardById(id).number
        end)
        table.sort(nums)
        if table.every(nums, function (num, i)
          return i == 1 or num == nums[i - 1] + 1
        end) then
          n = n + 1
        end
        if table.every(cards, function (id)
          return Fk:getCardById(id).trueName == first_card.trueName
        end) then
          n = n + 1
        end
      end
      event:setCostData(self, {cards = cards, n = n, audio_index = math.max(1, n)})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards ---@type integer[]
    local n = event:getCostData(self).n
    local x = #cards
    room:recastCard(cards, player, huazhang.name)
    if player.dead then return end
    if n > 0 then
      player:drawCards(x, huazhang.name)
      if player.dead then return end
    end
    if n > 1 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards.."-turn", x)
    end
    if n > 2 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards.."-turn", x)
      player:drawCards(x, huazhang.name)
    end
  end,
})

return huazhang
