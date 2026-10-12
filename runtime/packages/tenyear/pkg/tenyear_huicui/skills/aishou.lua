local aishou = fk.CreateSkill {
  name = "aishou",
}

Fk:loadTranslationTable{
  ["aishou"] = "隘守",
  [":aishou"] = "结束阶段，你可以摸X张牌（X为你的体力上限），这些牌标记为“隘”。当你于回合外失去最后一张“隘”后，你减1点体力上限。"..
  "准备阶段，弃置你手牌中的所有“隘”，若弃置的“隘”数大于你的体力值，你加1点体力上限。",

  ["@@aishou-inhand"] = "隘",

  ["$aishou1"] = "某家未闻有一合而破关之将。",
  ["$aishou2"] = "凭关而守，敌强又奈何？",
}

aishou:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(aishou.name) then
      if player.phase == Player.Finish then
        return true
      elseif player.phase == Player.Start then
        return table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 and not player:prohibitDiscard(id)
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Finish then
      return player.room:askToSkillInvoke(player, {
        skill_name = aishou.name,
      })
    elseif player.phase == Player.Start then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      player:drawCards(player.maxHp, aishou.name, "top", "@@aishou-inhand")
    else
      local cards = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 and not player:prohibitDiscard(id)
      end)
      room:throwCard(cards, aishou.name, player, player)
      if not player.dead and #cards > player.hp then
        room:changeMaxHp(player, 1)
      end
    end
  end,
})

aishou:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player.room.current ~= player and
      not table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@aishou-inhand") > 0
      end) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard:getMark("@@aishou-inhand") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
  end,
})

aishou:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@aishou-inhand", 0)
  end
end)

return aishou
