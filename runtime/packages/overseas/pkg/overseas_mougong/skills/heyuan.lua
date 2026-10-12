local os__heyuan = fk.CreateSkill {
  name = "os__heyuan",
}

Fk:loadTranslationTable{
  ["os__heyuan"] = "合援",
  [":os__heyuan"] = "结束阶段，你可以选择一名角色并弃置X张牌（X为你上次发动〖镇围〗时弃置的牌数），" ..
  "令其执行你于上次〖镇围〗执行的最后一项，且此后你对除其外的角色发动〖镇围〗时，该角色也可同时选择是否弃置牌" ..
  "（这些牌于计算〖镇围〗中的X时视为你弃置的牌）。",

  ["#os__heyuan-noDiscard"] = "合援：你可令一名满足条件角色执行记录效果",
  ["#os__heyuan-invoke"] = "合援：你可弃置%arg张牌，令一名满足条件角色执行记录效果",
  ["@[list]os__heyuan_owners-noclear"] = "合援",

  ["$os__heyuan1"] = "",
  ["$os__heyuan2"] = "",
}

os__heyuan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Finish and
      player:hasSkill(os__heyuan.name) and
      player:getMark("os__zhenweiz_discard-noclear") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local discardNum = math.max(0, player:getMark("os__zhenweiz_discard-noclear"))

    local tos, ids = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      min_card_num = discardNum,
      max_card_num = discardNum,
      pattern = ".",
      skill_name = os__heyuan.name,
      prompt = discardNum == 0 and "#os__heyuan-noDiscard" or "#os__heyuan-invoke:::" .. discardNum,
      will_throw = true,
    })

    if #tos == 1 then
      event:setCostData(self, { tos = tos, cards = ids })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards ---@type integer[]
    local skillName = os__heyuan.name
    local room = player.room

    if #cards > 0 then
      room:throwCard(cards, skillName, player, player)

      if not to:isAlive() then
        return false
      end
    end

    local lastEffect = player:getMark("@os__zhenweiz_effect-noclear")
    if type(lastEffect) == "string" then
      if lastEffect == "os__zhenweiz_effect_shield" then
        room:changeShield(to, 1)
      elseif lastEffect == "os__zhenweiz_effect_draw" then
        to:drawCards(4, skillName)
      else
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = skillName,
        }
      end
    end

    if not to:isAlive() then
      return false
    end

    room:addTableMarkIfNeed(to, "@[list]os__heyuan_owners-noclear", player)
  end,
})

return os__heyuan
