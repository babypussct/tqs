local quchong = fk.CreateSkill {
  name = "quchong",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") or Fk:currentRoom():isGameMode("2v2_mode") then
      return "quchong_1v2"
    else
      return "quchong_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["quchong"] = "渠冲",
  [":quchong"] = "出牌阶段，你可以重铸一张装备牌；每个回合结束时，你将弃牌堆中的装备牌移出游戏并获得等量铸造值；" ..
  "出牌阶段开始时，若场上没有【大攻车】（<a href=':offensive_siege_engine'>【大攻车·进击】</a>、"..
  "<a href=':defensive_siege_engine'>【大攻车·守御】</a>），则你可按铸造的次数以0、5、10、10点铸造值" ..
  "（若为2v2或斗地主模式，则改为0、2、5、5）选择一种大攻车并将之交给一名角色令其使用；否则你可以将场上的【大攻车】交给另一名角色并令其使用。",

  [":quchong_1v2"] = "出牌阶段，你可以重铸一张装备牌；每个回合结束时，你将弃牌堆中的装备牌移出游戏并获得等量铸造值；" ..
  "出牌阶段开始时，若场上没有【大攻车】（<a href=':offensive_siege_engine'>【大攻车·进击】</a>、"..
  "<a href=':defensive_siege_engine'>【大攻车·守御】</a>），则你可按铸造的次数以0、2、5、5点铸造值" ..
  "选择一种大攻车并将之交给一名角色令其使用；否则你可以将场上的【大攻车】交给另一名角色并令其使用。",
  [":quchong_role_mode"] = "出牌阶段，你可以重铸一张装备牌；每个回合结束时，你将弃牌堆中的装备牌移出游戏并获得等量铸造值；" ..
  "出牌阶段开始时，若场上没有【大攻车】（<a href=':offensive_siege_engine'>【大攻车·进击】</a>、"..
  "<a href=':defensive_siege_engine'>【大攻车·守御】</a>），则你可按铸造的次数以0、5、10、10点铸造值" ..
  "选择一种大攻车并将之交给一名角色令其使用；否则你可以将场上的【大攻车】交给另一名角色并令其使用。",

  ["@quchong_casting_point"] = "铸造值",
  ["#quchong"] = "渠冲：你可以重铸一张装备牌",
  ["#quchong-choose"] = "渠冲：你可以将场上的【大攻车】交给另一名角色并令其使用",
  ["#quchong-ask"] = "渠冲：请选择一种【大攻车】交给一名角色令其使用",

  ["$quchong1"] = "器有九距之备，亦有九攻之变。",
  ["$quchong2"] = "攻城之机变，于此车皆可解之！",
  ["$quchong3"] = "大攻起兮，可辟山海之艰！",
  ["$quchong4"] = "破坚如朽木，履高城如平地。",
}

quchong:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@quchong_casting_point", 0)
end)

quchong:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#quchong",
  card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, effect.from, quchong.name)
  end,
})

quchong:addEffect(fk.TurnEnd, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(quchong.name) and
      table.find(player.room.discard_pile,function(id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.discard_pile, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    if #cards > 0 then
      room:addPlayerMark(player, "@quchong_casting_point", #cards)
      room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, quchong.name, nil, true, player)
    end
  end,
})

quchong:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(quchong.name) and player.phase == Player.Play then
      if table.find(player.room.alive_players, function(p)
        return table.find(p:getCardIds("e"), function(id)
          return table.contains({ "offensive_siege_engine", "defensive_siege_engine" }, Fk:getCardById(id).name)
        end) ~= nil
      end) then
        return #player.room.alive_players > 1
      else
        local numList = { 0, 5, 10, 10 }
        if player.room:isGameMode("1v2_mode") or player.room:isGameMode("2v2_mode") then
          numList = { 0, 2, 5, 5 }
        end
        local times = player:getMark("quchong_crafted") + 1
        return times < 5 and player:getMark("@quchong_casting_point") >= numList[times]
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
      local room = player.room
      local siegeEngine
      if table.find(room.alive_players, function(p)
        return table.find(p:getCardIds("e"), function(id)
          siegeEngine = id
          return table.contains({ "offensive_siege_engine", "defensive_siege_engine" }, Fk:getCardById(id).name)
        end) ~= nil
      end) then
        local targets = table.filter(room.alive_players, function(p)
          return p ~= room:getCardOwner(siegeEngine)
        end)
        local tos = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#quchong-choose",
          skill_name = quchong.name,
          cancelable = true,
        })
        if #tos > 0 then
          event:setCostData(self, {tos = tos, cards = {siegeEngine}, choice = "move"})
          return true
        end
      else
        local success, dat = room:askToUseActiveSkill(player, {
          skill_name = "quchong_active",
          prompt = "#quchong-ask",
          cancelable = true,
        })
        if success and dat then
          event:setCostData(self, {tos = dat.targets, choice = "use", extra_data = dat.interaction})
          return true
        end
      end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if event:getCostData(self).choice == "use" then
      local numList = { 0, 5, 10, 10 }
      if room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode") then
        numList = { 0, 2, 5, 5 }
      end
      room:addPlayerMark(player, "quchong_crafted")
      local times = player:getMark("quchong_crafted")
      room:removePlayerMark(player, "@quchong_casting_point", numList[times])
      local name = event:getCostData(self).extra_data
      local siegeEngine = table.find(room:prepareDeriveCards({{ name, Card.Diamond, 1 }}, name.."_tag"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if siegeEngine then
        room:obtainCard(to, siegeEngine, true, fk.ReasonGive, player, quchong.name)
        if table.contains(to:getCardIds("h"), siegeEngine) and to:canUseTo(Fk:getCardById(siegeEngine), to) then
          room:useCard{
            from = to,
            card = Fk:getCardById(siegeEngine),
            tos = { to },
          }
        end
      end
    else
      local siegeEngine = event:getCostData(self).cards[1]
      room:obtainCard(to, siegeEngine, true, fk.ReasonGive, player, quchong.name)
      if table.contains(to:getCardIds("h"), siegeEngine) and to:canUseTo(Fk:getCardById(siegeEngine), to) then
        room:useCard{
          from = to,
          card = Fk:getCardById(siegeEngine),
          tos = { to },
        }
      end
    end
  end,
})

return quchong
