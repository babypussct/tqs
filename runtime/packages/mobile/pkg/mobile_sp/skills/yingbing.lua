local yingbing = fk.CreateSkill{
  name = "mobile__yingbing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__yingbing"] = "影兵",
  [":mobile__yingbing"] = "锁定技，有“咒”的角色使用与“咒”花色相同的牌时，你摸一张牌；若这是你第二次因该“咒”摸牌，移去该“咒”。",

  ["$mobile__yingbing1"] = "朱雀玄武，誓为我征！",
  ["$mobile__yingbing2"] = "所呼立至，所召立前！",
}

yingbing:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingbing.name) and #target:getPile("mobile__zhangbao_zhou") > 0 and
      data.card:compareSuitWith(Fk:getCardById(target:getPile("mobile__zhangbao_zhou")[1]))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local zhou = target:getPile("mobile__zhangbao_zhou")[1]
    player:drawCards(1, yingbing.name)
    if player.dead then return end
    local record = player:getTableMark(yingbing.name)
    local n = (record[tostring(zhou)] or 0) + 1
    if n == 2 then
      n = 0
      if table.contains(target:getPile("mobile__zhangbao_zhou"), zhou) then
        room:moveCardTo(zhou, Card.DiscardPile, player, fk.ReasonPutIntoDiscardPile, yingbing.name, nil, true, target)
      end
    end
    record[tostring(zhou)] = n
    room:setPlayerMark(player, yingbing.name, record)
  end,
})

return yingbing
