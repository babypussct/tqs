local binji = fk.CreateSkill {
  name = "binji",
}

Fk:loadTranslationTable{
  ["binji"] = "镔济",
  [":binji"] = "每轮开始时，你可以摸三张牌，然后交给至多三名其他角色各一张牌，"..
    "这些角色失去这些牌时从牌堆或弃牌堆随机获得一张武器牌，然后你摸一张牌。",

  ["#binji-give"] = "镔济：你可以交给至多三名其他角色各一张牌",
  ["@@binji-inhand"] = "镔济",

  ["$binji1"] = "好铁锻成好兵器，保准能捅贼将一万个窟窿！",
  ["$binji2"] = "这铁好啊，硬得像虎骨，韧得像龙筋。",
}

binji:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(binji.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, binji.name)
    room:askToYiji(player, {
      --cards = player:getCardIds("he"),
      targets = room:getOtherPlayers(player, false),
      skill_name = binji.name,
      min_num = 1,
      max_num = 3,
      prompt = "#binji-give",
      cancelable = false,
      single_max = 1,
      moveMark = {"@@binji-inhand", player.id}
    })
  end,
})

binji:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard:getMark("@@binji-inhand") ~= 0 then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local map = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local pid = info.beforeCard:getMark("@@binji-inhand")
          if pid ~= 0 then
            n = n + 1
            local p = room:getPlayerById(pid)
            map[p] = map[p] or 0
            map[p] = map[p] + 1
          end
        end
      end
    end
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|weapon", n)
    if #cards < n then
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|weapon", n - #cards, "discardPile"))
    end
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, binji.name)
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if map[p] and not p.dead then
        p:drawCards(map[p], binji.name)
      end
    end
  end,
})

return binji
