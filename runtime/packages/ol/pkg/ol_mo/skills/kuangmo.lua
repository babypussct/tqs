local kuangmo = fk.CreateSkill{
  name = "kuangmo",
}

Fk:loadTranslationTable{
  ["kuangmo"] = "狂魔",
  [":kuangmo"] = "出牌阶段，你可以<a href='#RuMoDesc'><font color='red'>入魔</font></a>并选择一名其他角色，你与其成为“狂”角色，"..
    "每回合对彼此首次造成的伤害+1；击败对方后，获得对方所有“炁”。“狂”角色死亡后，你重新指定。",

  ["#kuangmo"] = "狂魔：选择一名其他角色，与其成为“狂”角色",
  ["@@kuangmo"] = "狂",
  ["#kuangmo-choose"] = "狂魔：重新选择一名其他角色成为“狂”角色",

  ["$kuangmo1"] = "草芥，也配呼吸？",
  ["$kuangmo2"] = "哼，蝼蚁，杀了解闷。",
  ["$kuangmo3"] = "骄狂纵意，天地唯我！",
}

kuangmo:addEffect("active", {
  anim_type = "big",
  prompt = "#kuangmo",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:hasSkill("#rumo", true)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, "@@kuangmo", 1)
    room:setPlayerMark(target, "@@kuangmo", 1)
    room:setPlayerMark(player, "kuangmo_target", target.id)
    room:handleAddLoseSkills(player, "#rumo", nil, false, true)
  end,
})

kuangmo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    --实测为延迟效果，发动者为造成伤害的角色，被防止的伤害也参与计算（直接取首次伤害事件）
    if player == target and not player.dead and player.room:getCurrent() and
      (player:getMark("kuangmo_target") == data.to.id or data.to:getMark("kuangmo_target") == player.id) then
      local damages = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
        local damage = e.data
        return player == damage.from and data.to == damage.to
      end, Player.HistoryTurn)
      return #damages > 0 and damages[1] == player.room.logic:getCurrentEvent()
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

kuangmo:addEffect(fk.Death, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    --实测为延迟效果，发动者固定为魔吕布
    if player == target then
      return data.damage and data.damage.from and player:getMark("kuangmo_target") == data.damage.from.id
    else
      return not player.dead and player:getMark("kuangmo_target") == target.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { player.room:getPlayerById(player:getMark("kuangmo_target")) } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local winner = nil
    if player == target then
      winner = event:getCostData(self).tos[1]
      cards = player:getTableMark("duoqi_record")[tostring(player.id)]
    elseif data.damage and data.damage.from == player then
      winner = player
      cards = player:getTableMark("duoqi_record")[tostring(target.id)]
    end
    if winner and cards then
      --实测先获得牌堆+弃牌堆里的所有炁，再获得所有角色的区域里的炁，不同reason的move是不会同时进行的
      local to_get = table.filter(room.discard_pile, function (id)
        return table.contains(cards, id)
      end)
      table.insertTable(to_get, table.filter(room.draw_pile, function (id)
        return table.contains(cards, id)
      end))
      if #to_get > 0 then
        room:obtainCard(winner, to_get, false, fk.ReasonJustMove, winner, kuangmo.name)
      end
      if not winner.dead then
        local handcards = winner:getCardIds("h")
        local player_places = { Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }
        to_get = table.filter(cards, function(id)
          return not table.contains(handcards, id) and table.contains(player_places, room:getCardArea(id))
        end)
        if #to_get > 0 then
          room:obtainCard(winner, to_get, false, fk.ReasonPrey, winner, kuangmo.name)
        end
      end
    end
    if player ~= target then
      local tos = room:getOtherPlayers(player, false)
      if #tos > 0 then
        tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = tos,
          skill_name = kuangmo.name,
          prompt = "#kuangmo-choose",
          cancelable = false,
        })
        room:setPlayerMark(tos[1], "@@kuangmo", 1)
        room:setPlayerMark(player, "kuangmo_target", tos[1].id)
      end
    end
  end,
})

kuangmo:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark("kuangmo_target") ~= 0 then
    local to = room:getPlayerById(player:getMark("kuangmo_target"))
    room:setPlayerMark(player, "kuangmo_target", 0)
    if to and not to.dead then
      if table.every(room.alive_players, function (p)
        return p:getMark("kuangmo_target") ~= to.id
      end) then
        room:setPlayerMark(to, "@@kuangmo", 0)
      end
    end
  end
end)

--FIXME:缺死亡清理（线上也没做，先摆）

return kuangmo
