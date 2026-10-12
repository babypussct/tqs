local skill = fk.CreateSkill{
  name = "#crow_bow_skill",
  attached_equip = "crow_bow",
}

skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end) then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            end
          end
        end
      end
      if n > 1 then
        event:setCostData(self, { n = n })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local n = event:getCostData(self).n
    local to = room:askToChoosePlayers(player, {
      skill_name = skill.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#crow_bow-choose:::"..n,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to, n = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).n
    local to = event:getCostData(self).tos[1]
    local cards = room:askToChooseCards(player, {
      target = to,
      min = n,
      max = n,
      flag = "he",
      skill_name = skill.name,
    })
    room:throwCard(cards, skill.name, to, player)
  end,
})

return skill
