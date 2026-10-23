local sijian = fk.CreateSkill{
  name = "sijian",
}

Fk:loadTranslationTable{
  ["sijian"] = "死谏",
  [":sijian"] = "当你失去手牌后，若你没有手牌，你可以弃置一名其他角色的一张牌。",

  ["#sijian-choose"] = "死谏：你可以弃置一名其他角色的一张牌",

  ["$sijian2"] = "忠言逆耳啊！！",
  ["$sijian1"] = "且听我最后一言！",
}

sijian:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(sijian.name) and player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#sijian-choose",
      skill_name = sijian.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = sijian.name,
    })
    room:throwCard(id, sijian.name, to, player)
  end,
})

local AI = Fk.Ltk.AI
sijian:addAI(AI.reuse("xuanfeng", AI.ChoosePlayersStrategy))

return sijian
