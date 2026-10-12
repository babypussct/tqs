local zhenxing = fk.CreateSkill{
  name = "ty__zhenxing",
}

Fk:loadTranslationTable{
  ["ty__zhenxing"] = "镇行",
  [":ty__zhenxing"] = "结束阶段或当你受到伤害后，你可以观看牌堆顶三张牌，然后获得其中与其余牌花色均不同的一张牌，"..
  "并将剩余的牌置于牌堆顶，称为“信”。",

  ["#ty__zhenxing-prey"] = "镇行：你可以获得其中一张牌，其余牌作为“信”",

  ["$ty__zhenxing1"] = "边境镇威，万军难进。",
  ["$ty__zhenxing2"] = "兵行万土，得御安危。",
}

Fk:addPoxiMethod{
  name = zhenxing.name,
  prompt = "#ty__zhenxing-prey",
  card_filter = function(to_select, selected, data)
    if #selected == 0 then
      return not table.find(data[1][2], function (id)
        return id ~= to_select and Fk:getCardById(id):compareSuitWith(Fk:getCardById(to_select))
      end)
    end
  end,
  feasible = function(selected)
    return #selected == 1
  end,
}

---@type TrigSkelSpec<TrigFunc>
local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, zhenxing.name, false)
    local result = room:askToPoxi(player, {
      poxi_type = zhenxing.name,
      data = { { "Top", cards } },
      cancelable = true,
    })
    if #result > 0 then
      table.removeOne(cards, result[1])
      room:obtainCard(player, result, false, fk.ReasonJustMove, player, zhenxing.name)
    end
    if player:hasSkill("qianxinz", true) then
      local mark = player:getTableMark("zhanggong_mail")
      table.insertTableIfNeed(mark, cards)
      room:setPlayerMark(player, "zhanggong_mail", mark)
      room:setPlayerMark(player, "@zhanggong_mail", #mark)
    end
    room:returnCardsToDrawPile(player, cards, zhenxing.name, "top", false)
  end,
}

zhenxing:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenxing.name)
  end,
  on_use = spec.on_use,
})

zhenxing:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenxing.name) and player.phase == Player.Finish
  end,
  on_use = spec.on_use,
})

return zhenxing
