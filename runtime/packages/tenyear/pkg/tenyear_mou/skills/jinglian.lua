
local jinglian = fk.CreateSkill{
  name = "jinglian",
}

Fk:loadTranslationTable{
  ["jinglian"] = "精练",
  [":jinglian"] = "每个回合结束时，若你本回合至少失去过两张牌，则你可以摸三张牌。"..
  "若摸的牌里有装备牌或多目标锦囊牌，则你可以弃置之并对等量名其他角色各造成1点伤害。",

  ["#jinglian-choose"] = "精练：你可以弃置其中的装备牌和多目标锦囊牌，对至多%arg名角色各造成1点伤害",

  ["$jinglian1"] = "",
  ["$jinglian2"] = "",
}

jinglian:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jinglian.name) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
        if n > 1 then
          return true
        end
      end, Player.HistoryTurn)
      return n > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(3, jinglian.name)
    cards = table.filter(cards, function (id)
      local card = Fk:getCardById(id)
      if card.type == Card.TypeEquip or (card.multiple_targets and card.type == Card.TypeTrick) then
        return table.contains(player:getCardIds("h"), id) and not player:prohibitDiscard(id)
      end
    end)
    if #cards > 0 and #room:getOtherPlayers(player, false) > 0 then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = #cards,
        targets = room:getOtherPlayers(player, false),
        skill_name = jinglian.name,
        prompt = "#jinglian-choose:::" .. #cards,
        cancelable = true,
      })
      if #tos > 0 then
        room:throwCard(cards, jinglian.name, player, player)
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = jinglian.name,
            }
          end
        end
      end
    end
  end,
})

return jinglian
