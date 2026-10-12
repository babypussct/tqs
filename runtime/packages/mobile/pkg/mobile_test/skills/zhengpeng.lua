local zhengpeng = fk.CreateSkill {
  name = "zhengpeng",
}

Fk:loadTranslationTable{
  ["zhengpeng"] = "征蓬",
  [":zhengpeng"] = "一名角色的回合结束时，你可以选择一名符合条件的角色并失去X点体力（X为本轮本技能发动次数），其于本回合内每满足一项，"..
  "你摸一张牌：受到过伤害，失去过装备牌，非当前回合角色且获得过牌。"..
  "<a href='#ChengShi'>乘势</a>：重置本技能的X，然后你获得弃牌堆中每种类型的牌各一张。",

  ["#zhengpeng-choose"] = "征蓬：你可以选择一名角色，失去%arg点体力，摸对应数量的牌",

  ["$zhengpeng1"] = "铁甲展开，护其周身！",
  ["$zhengpeng2"] = "我来为主公荡平前路！",
}

Fk:addTargetTip{
  name = zhengpeng.name,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if selectable then
      local n = extra_data.extra_data[tostring(to_select.id)]
      if n > 0 then
        return "draw"..n
      end
    end
  end,
}

zhengpeng:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengpeng.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets1, targets2, targets3 = {}, {}, {}
    room.logic:getActualDamageEvents(1, function (e)
      if not e.data.to.dead then
        table.insertIfNeed(targets1, e.data.to)
      end
    end, Player.HistoryTurn)
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from and not move.from.dead and not table.contains(targets2, move.from) then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard.type == Card.TypeEquip and
              (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              table.insert(targets2, move.from)
            end
          end
        end
        if move.to and move.to ~= target and not move.to.dead and not table.contains(targets3, move.to) and
          move.toArea == Card.PlayerHand then
          table.insert(targets3, move.to)
        end
      end
    end, Player.HistoryTurn)
    local mapper = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      local n = 0
      if table.contains(targets1, p) then
        n = n + 1
      end
      if table.contains(targets2, p) then
        n = n + 1
      end
      if table.contains(targets3, p) then
        n = n + 1
      end
      mapper[tostring(p.id)] = n
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = zhengpeng.name,
      prompt = "#zhengpeng-choose:::"..player:usedSkillTimes(zhengpeng.name, Player.HistoryRound),
      cancelable = true,
      target_tip_name = zhengpeng.name,
      extra_data = mapper,
    })
    if #to > 0 then
      event:setCostData(self, { choice = mapper[tostring(to[1].id)] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    if player:usedSkillTimes(zhengpeng.name, Player.HistoryRound) > 1 then
      room:loseHp(player, player:usedSkillTimes(zhengpeng.name, Player.HistoryRound) - 1, zhengpeng.name, player)
      if player.dead then return end
    end
    player:drawCards(n, zhengpeng.name)
    if player.dead then return end
    if n == 3 then
      player:setSkillUseHistory(zhengpeng.name, 0, Player.HistoryRound)
      local cards = {}
      for _, type in ipairs({ "basic", "trick", "equip" }) do
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..type, 1, "discardPile"))
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, zhengpeng.name, nil, false, player)
      end
    end
  end,
})

return zhengpeng
