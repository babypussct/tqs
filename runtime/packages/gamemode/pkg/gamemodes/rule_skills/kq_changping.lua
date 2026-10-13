local changping = fk.CreateSkill {
  name = "#kq__changping",
}

Fk:loadTranslationTable{
  ["#kq__changping"] = "长平之战",
  [":#kq__changping"] = "游戏开始时，进入鏖战状态（所有角色只能将【桃】当【杀】或【闪】使用或打出）；当一名角色成为【杀】的目标时，"..
  "其需要额外使用一张【闪】抵消之；若场上有白起，则秦势力角色的回合开始时，其获得一张【桃】。",
}

changping:addEffect(fk.GameStart, {
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setBanner("@[:]BattleRoyalDummy", "BattleRoyalMode")
    for _, p in ipairs(room.players) do
      room:handleAddLoseSkills(p, "battle_royal&", nil, false, true)
    end
  end,
})

changping:addEffect(fk.TargetConfirmed, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    data:setResponseTimes(data:getResponseTimes() + 1)
  end,
})

changping:addEffect(fk.TurnStart, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.kingdom == "qin" and
      table.find(player.room.alive_players, function (p)
        return Fk.generals[p.general].trueName == "baiqi" or (Fk.generals[p.deputyGeneral] or {}).trueName == "baiqi"
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("peach", 1, "allPiles")
    if #card > 0 then
      room:obtainCard(player, card, true, fk.ReasonJustMove)
    end
  end,
})

return changping
