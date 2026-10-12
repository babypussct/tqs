local osShoushou = fk.CreateSkill {
  name = "os__shoushou"
}

Fk:loadTranslationTable{
  ["os__shoushou"] = "收绶",
  [":os__shoushou"] = "①当你获得其他角色的牌后，若你在一名角色的攻击范围内，其他角色至你距离+1。" ..
  "②当你造成或受到伤害后，若你不在一名角色的攻击范围内，其他角色至你距离-1。",

  ["@os__shoushou"] = "收绶 至",

  ["$os__shoushou1"] = "此印既授，吾自当收之！",
  ["$os__shoushou2"] = "本初虽已示弱，此仇亦不能饶！",
}

osShoushou:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osShoushou.name) then
      return false
    end

    local invoke = false
    for _, move in ipairs(data) do
      if move.to == player and move.from and move.from ~= player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            invoke = true
            break
          end
        end
        if invoke then
          break
        end
      end
    end
    if
      invoke and
      table.find(player.room.alive_players, function(p)
        return p:inMyAttackRange(player)
      end)
    then
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local num = tonumber(player:getMark("@os__shoushou"))
    num = num + 1
    player.room:setPlayerMark(player, "@os__shoushou", num > 0 and "+" .. tostring(num) or tostring(num))
  end,
})

local osShoushouDamageSpec = {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and player:hasSkill(osShoushou.name) and
      table.find(player.room.alive_players, function(p)
        return p ~= player and not p:inMyAttackRange(player)
      end) and
      player:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local num = tonumber(player:getMark("@os__shoushou"))
    num = num - 1
    player.room:setPlayerMark(player, "@os__shoushou", num > 0 and "+" .. tostring(num) or tostring(num))
  end,
}

osShoushou:addEffect(fk.Damage, osShoushouDamageSpec)

osShoushou:addEffect(fk.Damaged, osShoushouDamageSpec)

osShoushou:addEffect("distance", {
  correct_func = function(self, from, to)
    if to:getMark("@os__shoushou") ~= 0 and from ~= to then
      return tonumber(to:getMark("@os__shoushou"))
    end
  end,
})

return osShoushou
