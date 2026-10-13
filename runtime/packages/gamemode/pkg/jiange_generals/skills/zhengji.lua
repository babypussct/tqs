local zhengji = fk.CreateSkill {
  name = "jiange__zhengji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__zhengji"] = "整纪",
  [":jiange__zhengji"] = "锁定技，当友方角色装备区内的牌被弃置后，你令所有友方角色各摸一张牌。",
}

zhengji:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhengji.name) then
      for _, move in ipairs(data) do
        if move.from and move.from:isFriend(player) and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = player:getFriends()
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and p:isFriend(player) then
        p:drawCards(1, zhengji.name)
      end
    end
  end,
})

return zhengji
