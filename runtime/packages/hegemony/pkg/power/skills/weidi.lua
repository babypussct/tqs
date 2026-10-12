local weidi = fk.CreateSkill{
  name = "ld__weidi",
}

Fk:loadTranslationTable{
  ["ld__weidi"] = "伪帝",
  [":ld__weidi"] = "出牌阶段限一次，你可以选择一名本回合从牌堆获得过牌的其他角色，对其发起“军令”。若其不执行，你获得其所有手牌，然后交给其等量的牌。",

  ["#ld__weidi"] = "伪帝：对一名角色发起“军令”，若其不执行则获得其所有手牌并交还等量的牌",
  ["#ld__weidi-cards"] = "伪帝：交给 %dest %arg张牌",

  ["$ld__weidi1"] = "你们都得听我的号令！",
  ["$ld__weidi2"] = "我才是皇帝！",
}

local H = require "packages.hegemony.util"

weidi:addEffect("active", {
  anim_type = "control",
  prompt = "#ld__weidi",
  can_use = function(self, player)
    return player:usedSkillTimes(weidi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player and to_select:getMark("_ld__weidi-turn") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if not H.askToCommand(player, { tos = { target }, skill_name = weidi.name }) and not target:isKongcheng() then
      local cards = target:getCardIds("h")
      room:obtainCard(player, cards, false, fk.ReasonPrey)
      local num = #cards
      local cids = player:getCardIds("he")
      if #cids > num then
        cids = room:askToCards(player, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = weidi.name,
          prompt = "#ld__weidi-cards::" .. target.id .. ":" .. num,
          cancelable = false,
        })
      end
      if #cids > 0 then
        room:moveCardTo(cids, Player.Hand, target, fk.ReasonGive, weidi.name, nil, false, player)
      end
    end
  end,
})
local setWeidiMark = function (room, data)
  for _, move in ipairs(data) do
    if move.toArea == Card.PlayerHand and move.to then
      local to = move.to
      if to and to:getMark("_ld__weidi-turn") == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile and to:getMark("_ld__weidi-turn") == 0 then
            room:setPlayerMark(to, "_ld__weidi-turn", 1)
          end
        end
      end
    end
  end
end
weidi:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(weidi.name) and player.room.current == player
  end,
  on_refresh = function(self, event, target, player, data)
    setWeidiMark(player.room, data)
  end,
})
weidi:addAcquireEffect(function (self, player, is_start)
  if is_start then return end
  local room = player.room
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
    setWeidiMark(room, e.data)
    return false
  end, Player.HistoryTurn)
end)

return weidi
