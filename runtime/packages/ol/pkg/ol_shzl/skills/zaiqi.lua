local zaiqi = fk.CreateSkill {
  name = "ol__zaiqi",
}

Fk:loadTranslationTable{
  ["ol__zaiqi"] = "再起",
  [":ol__zaiqi"] = "摸牌阶段，若你已受伤，你可以放弃摸牌，改为亮出牌堆顶X+1张牌（X为你已损失体力值），"..
  "你将其中的<font color='red'>♥</font>牌置入弃牌堆并回复等量体力，获得其余的牌。",

  ["$ol__zaiqi1"] = "汉人奸诈，还是不服，再战！",
  ["$ol__zaiqi2"] = "胜败乃常事，无妨！",
}

zaiqi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zaiqi.name) and player.phase == Player.Draw and
      not data.phase_end and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local n = player:getLostHp() + 1
    local cards = room:getNCards(n)
    room:turnOverCardsFromDrawPile(player, cards, zaiqi.name)
    room:delay(2000)
    local hearts, to_get = {}, {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).suit == Card.Heart then
        table.insert(hearts, id)
      else
        table.insert(to_get, id)
      end
    end
    if #hearts > 0 then
      room:recover{
        who = player,
        num = #hearts,
        recoverBy = player,
        skillName = zaiqi.name,
      }
    end
    if #to_get > 0 and not player.dead then
      room:obtainCard(player, to_get, true, fk.ReasonJustMove, player, zaiqi.name)
    end
    room:cleanProcessingArea(cards)
  end,
})

return zaiqi
