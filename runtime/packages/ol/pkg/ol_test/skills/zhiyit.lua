
local zhiyit = fk.CreateSkill{
  name = "zhiyit",
}

Fk:loadTranslationTable{
  ["zhiyit"] = "知意",
  [":zhiyit"] = "每回合限一次，当你获得牌后或其他角色获得你的牌后，若你手牌中有其他此颜色的牌，你可以令一名角色摸一张牌。",

  ["#zhiyit-choose"] = "知意：你可以令一名角色摸一张牌",

  ["$zhiyit1"] = "",
  ["$zhiyit2"] = "",
}

zhiyit:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiyit.name) and
      player:usedSkillTimes(zhiyit.name, Player.HistoryTurn) == 0 and not player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.to and (move.to == player or move.from == player) and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.find(player:getCardIds("h"), function (id)
              return id ~= info.cardId and Fk:getCardById(id):compareColorWith(info.beforeCard)
            end) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#zhiyit-choose",
      skill_name = zhiyit.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, zhiyit.name)
  end,
})

local AI = Fk.Ltk.AI
zhiyit:addAI(AI.reuse("zuoding", AI.ChoosePlayersStrategy))

return zhiyit
