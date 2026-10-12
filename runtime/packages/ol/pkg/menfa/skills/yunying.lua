
local yunying = fk.CreateSkill {
  name = "yunying",
  tags = { Skill.Compulsory },
  add_skills = { "#ThisTurnDiscardedRecorder" },
}

Fk:loadTranslationTable{
  ["yunying"] = "云影",
  [":yunying"] = "锁定技，每个结束阶段，上次〖遁迹〗目标角色每满足一项，你便执行一项："..
  "1，本回合扣减过体力，你将所有黑色手牌当无距离限制的【杀】使用；2.本回合失去过手牌，你将手牌摸至X张（X为本回合弃牌堆中黑色牌数且至多为5）。",

  ["#yunying-use"] = "云影：请将所有黑色手牌当无距离限制的【杀】使用",

  ["$yunying1"] = "",
  ["$yunying2"] = "",
}

yunying:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunying.name) and target.phase == Player.Finish and
      (player:getMark("@[chara]dunji") ~= 0 and
      #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.who.id == player:getMark("@[chara]dunji") and e.data.num < 0
      end, Player.HistoryTurn) > 0 or
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from and move.from.id == player:getMark("@[chara]dunji") then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local who = room:getPlayerById(player:getMark("@[chara]dunji"))
    if #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.who == who and e.data.num < 0
      end, Player.HistoryTurn) > 0 then
      local card = Fk:cloneCard("slash")
      card.skillName = yunying.name
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).color == Card.Black then
          card:addSubcard(id)
        end
      end
      if #card.subcards > 0 and player:canUse(card, { bypass_distances= true, bypass_times = true }) then
        room:askToUseVirtualCard(player, {
          name = "slash",
          skill_name = yunying.name,
          prompt = "#yunying-use",
          cancelable = false,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            extraUse = true,
          },
          subcards = card.subcards,
        })
      end
    end
    if player.dead then return end
    if #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == who then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0 then
      local n = #table.filter(room:getBanner("ThisTurnDiscarded-turn") or {}, function (id)
        return Fk:getCardById(id).color == Card.Black
      end)
      n = math.min(n, 5)
      if n > player:getHandcardNum() then
        player:drawCards(n - player:getHandcardNum(), yunying.name)
      end
    end
  end,
})

return yunying
