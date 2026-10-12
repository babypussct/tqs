
local duzuo = fk.CreateSkill {
  name = "duzuo",
}

Fk:loadTranslationTable{
  ["duzuo"] = "督佐",
  [":duzuo"] = "你不因此技能获得牌后，可以令一名角色获得一张火【杀】。",

  ["#duzuo-choose"] = "督佐：你可以令一名角色获得一张火【杀】",

  ["$duzuo1"] = "你我各执万兵，曹贼将以何胜？",
  ["$duzuo2"] = "如今大敌临前，我当为君助！",
}

duzuo:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(duzuo.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.skillName ~= duzuo.name then
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      prompt = "#duzuo-choose",
      skill_name = duzuo.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:getCardsFromPileByRule(".|.|.|.|fire__slash")
    if #card == 0 then
      card = room:getCardsFromPileByRule(".|.|.|.|fire__slash", 1, "discardPile")
    end

    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonJustMove, duzuo.name, nil, false, player)
    end
  end,
})

return duzuo
