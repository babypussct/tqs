
local xieshi = fk.CreateSkill {
  name = "xieshi",
}

Fk:loadTranslationTable{
  ["xieshi"] = "挟势",
  [":xieshi"] = "每个回合的结束阶段，若你手牌数与本回合开始不同，你可以视为使用一张本回合进入弃牌堆的基本牌或普通锦囊牌。",
  --"若本回合你手牌变化数不小于此牌目标手牌变化数，此牌不可被响应。",

  ["#xieshi-use"] = "挟势：你可以视为使用一张基本牌或单目标普通锦囊牌",

  ["$xieshi1"] = "",
  ["$xieshi2"] = "",
}

xieshi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xieshi.name) and target.phase == Player.Finish and
      player:getHandcardNum() ~= player:getMark("xieshi-turn")[player] and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                local card = Fk:getCardById(info.cardId)
                if card.type == Card.TypeBasic or (card:isCommonTrick() and not card.is_passive and not card.multiple_targets) then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player.room.discard_pile, info.cardId) then
              local card = Fk:getCardById(info.cardId)
              if card.type == Card.TypeBasic or (card:isCommonTrick() and not card.is_passive and not card.multiple_targets) then
                table.insertIfNeed(names, card.name)
              end
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local use = room:askToUseVirtualCard(player, {
      name = names,
      skill_name = xieshi.name,
      prompt = "#xieshi-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    --if math.abs(player:getHandcardNum() - player:getMark("xieshi-turn")[player]) >=
    --  math.abs(use.tos[1]:getHandcardNum() - player:getMark("xieshi-turn")[use.tos[1]]) then
    --  use.disresponsiveList = table.simpleClone(room.players)
    --end
    room:useCard(use)
  end,
})

xieshi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xieshi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, p in ipairs(room.players) do
      mark[p] = p:getHandcardNum()
    end
    room:setPlayerMark(player, "xieshi-turn", mark)
  end,
})

xieshi:addAcquireEffect(function (self, player, is_start, src)
  if not is_start then
    local room = player.room
    local mark = {}
    for _, p in ipairs(room.players) do
      mark[p] = p:getHandcardNum()
    end
    room:setPlayerMark(player, "xieshi-turn", mark)
  end
end)

return xieshi
