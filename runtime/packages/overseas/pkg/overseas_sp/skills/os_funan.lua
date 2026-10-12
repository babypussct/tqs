local osFunan = fk.CreateSkill {
  name = "os__funan"
}

Fk:loadTranslationTable{
  ["os__funan"] = "复难",
  [":os__funan"] = "1级：其他角色响应你使用的牌时，你可令其获得你使用的牌，其本回合不能使用或打出之，" ..
  "然后你获得其使用或打出的牌。<br/>2级：其他角色响应你使用的牌时，你可获得其使用或打出的牌。",

  ["@@os__funan_update"] = "复难2级",

  ["$os__funan1"] = "礼尚往来，乃君子风范。",
  ["$os__funan2"] = "以子之矛，攻子之盾。",
}

local osFunanSpec = {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osFunan.name) and
      data.responseToEvent and
      data.responseToEvent.from == player and
      target ~= player and
      (
        (
          player:getMark("@@os__funan_update") == 0 and
          data.responseToEvent.card and
          player.room:getCardArea(data.responseToEvent.card) == Card.Processing
        ) or
        (
          player:getMark("@@os__funan_update") > 0 and
          data.card and
          player.room:getCardArea(data.card) == Card.Processing
        )
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@os__funan_update") == 0 then
      local card = data.responseToEvent.card
      room:obtainCard(target, card, false, fk.ReasonPrey, target)
      local cidsRecorded = target:getTableMark("_os__funan-turn")
      table.insertTable(cidsRecorded, Card:getIdList(card))
      room:setPlayerMark(target, "_os__funan-turn", cidsRecorded)
    end
    if data.card and player:isAlive() then
      room:obtainCard(player, data.card, false, fk.ReasonPrey, player)
    end
  end,
}

osFunan:addEffect(fk.CardUsing, osFunanSpec)

osFunan:addEffect(fk.CardResponding, osFunanSpec)

osFunan:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return table.contains(player:getTableMark("_os__funan-turn"), card.id)
  end,
  prohibit_response = function(self, player, card)
    return table.contains(player:getTableMark("_os__funan-turn"), card.id)
  end,
})

return osFunan
