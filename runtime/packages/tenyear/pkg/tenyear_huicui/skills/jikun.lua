local jikun = fk.CreateSkill {
  name = "jikun",
}

Fk:loadTranslationTable {
  ["jikun"] = "济困",
  [":jikun"] = "每当你失去五张牌后，你可以选择一名其他角色，令其随机获得每名手牌数最多的角色各一张牌。",

  ["@jikun"] = "济困",
  ["#jikun-choose"] = "济困：令一名角色获得手牌数最多的角色各一张牌",

  ["$jikun1"] = "夫妻结发，焉有辕辙异向之理？",
  ["$jikun2"] = "五嫒同室，必宜其家。",
}

jikun:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jikun.name) then
      for _, move in ipairs(data) do
        if move.extra_data and move.extra_data.jikun and table.contains(move.extra_data.jikun, player.id) then
          return #player.room:getOtherPlayers(player, false) > 0 and
              table.find(player.room.alive_players, function(p)
                return not p:isNude()
              end)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, move in ipairs(data) do
      if move.extra_data and move.extra_data.jikun and table.contains(move.extra_data.jikun, player.id) then
        n = n + #table.filter(move.extra_data.jikun, function(pid)
          return pid == player.id
        end)
      end
    end
    for i = 1, n do
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = jikun.name,
        prompt = "#jikun-choose",
        cancelable = true,
      })
      local to = tos[1]
      local targets = table.filter(room.alive_players, function(p)
        return table.every(room.alive_players, function(q)
          return p:getHandcardNum() >= q:getHandcardNum()
        end)
      end)
      table.removeOne(targets, to)
      targets = table.filter(targets, function(p)
        return not p:isNude()
      end)
      if #targets == 0 then return end
      room:sortByAction(targets)
      local moves = {}
      for _, p in ipairs(targets) do
        table.insert(moves, {
          ids = room:tableRandomPick(p:getCardIds("he"), 1),
          from = p,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          skillName = jikun.name,
          proposer = to,
          moveVisible = false,
        })
      end
      room:moveCards(table.unpack(moves))
    end
  end,

  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(jikun.name, true) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player and player:hasSkill(jikun.name, true) then
        if move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              room:addPlayerMark(player, "@jikun", 1)
              while player:getMark("@jikun") >= 5 do
                room:removePlayerMark(player, "@jikun", 5)
                move.extra_data = move.extra_data or {}
                move.extra_data.jikun = move.extra_data.jikun or {}
                table.insert(move.extra_data.jikun, player.id)
              end
            end
          end
        else
          local parent_event = player.room.logic:getCurrentEvent().parent
          if parent_event ~= nil then
            if parent_event.event == GameEvent.UseCard then
              local use = parent_event.data
              if use.from ~= player or use.card.type ~= Card.TypeEquip then
                parent_event:searchEvents(GameEvent.MoveCards, 1, function(e2)
                  if e2.parent and e2.parent.id == parent_event.id then
                    for _, move2 in ipairs(e2.data) do
                      if move2.from == player and move2.moveReason == fk.ReasonUse then
                        for _, info in ipairs(move2.moveInfo) do
                          if info.fromArea == Card.PlayerHand and
                              (use.card.type ~= Card.TypeEquip or Fk:getCardById(info.cardId).type == Card.TypeEquip) then
                            room:addPlayerMark(player, "@jikun", 1)
                            while player:getMark("@jikun") >= 5 do
                              room:removePlayerMark(player, "@jikun", 5)
                              move.extra_data = move.extra_data or {}
                              move.extra_data.jikun = move.extra_data.jikun or {}
                              table.insert(move.extra_data.jikun, player.id)
                            end
                          end
                        end
                      end
                    end
                  end
                end)
              end
            end
          end
        end
      end
    end
  end,
})

jikun:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@jikun", 0)
end)

return jikun
