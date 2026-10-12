local quanjin = fk.CreateSkill {
  name = "quanjin",
}

Fk:loadTranslationTable {
  ["quanjin"] = "劝进",
  [":quanjin"] = "出牌阶段限一次，你可以将一张手牌交给一名此阶段受到过伤害的角色，对其发起“军令”。"..
  "若其执行，你摸一张牌；若其不执行，你将手牌摸至与手牌最多的角色相同（最多摸五张）。",

  ["#quanjin"] = "劝进：将一张手牌交给一名角色，对其发起军令，你摸牌",

  ["$quanjin1"] = "今称魏公，则可以藩卫之名，征吴伐蜀也。",
  ["$quanjin2"] = "明公受封，正合天心人意！",
}

local H = require "packages.hegemony.util"

quanjin:addEffect("active", {
  anim_type = "control",
  prompt = "#quanjin",
  can_use = function(self, player)
    return player:usedSkillTimes(quanjin.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and #selected_cards == 1 and to_select:getMark("quanjin-phase") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, quanjin.name, nil, false, player)
    if H.askToCommand(player, {
      tos = { target },
      skill_name = quanjin.name,
    }) and not player.dead then
      player:drawCards(1, quanjin.name)
    else
      local num = player:getHandcardNum()
      for _, p in ipairs(room.alive_players) do
        local n = p:getHandcardNum()
        if n > num then
          num = n
        end
      end
      num = math.min(num - player:getHandcardNum(), 5)
      if num > 0 and not player.dead then
        player:drawCards(num, quanjin.name)
      end
    end
  end,
})

quanjin:addAcquireEffect(function(self, player, is_start)
  if is_start then return end
  local room = player.room
  room.logic:getActualDamageEvents(1, function(e)
    room:setPlayerMark(e.data.to, "quanjin-phase", 1)
  end, Player.HistoryPhase)
end)

quanjin:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(quanjin.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "quanjin-phase", 1)
  end,
})

return quanjin
