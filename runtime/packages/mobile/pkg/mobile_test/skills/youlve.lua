local youlve = fk.CreateSkill {
  name = "youlve",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["youlve"] = "游掠",
  [":youlve"] = "锁定技，你于回合内不以此法获得一张牌后，你摸一张牌：你于回合外不以此法失去一张牌后，你弃置一张牌。",

  ["$youlve1"] = "秋高马肥，正宜南下！",
  ["$youlve2"] = "追兵在即，吾等还需亲身上阵！",
}

youlve:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youlve.name) then
      if player.room:getCurrent() == player then
        for _, move in ipairs(data) do
          if move.to == player and move.toArea == Player.Hand and move.skillName ~= youlve.name then
            return true
          end
        end
      else
        for _, move in ipairs(data) do
          if move.from == player and move.skillName ~= youlve.name then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(youlve.name)
    local n = 0
    if room:getCurrent() == player then
      room:notifySkillInvoked(player, youlve.name, "drawcard")
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.skillName ~= youlve.name then
          n = n + #move.moveInfo
        end
      end
      player:drawCards(n, youlve.name)
    else
      room:notifySkillInvoked(player, youlve.name, "negative")
      for _, move in ipairs(data) do
        if move.from == player and move.skillName ~= youlve.name then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              n = n + 1
            end
          end
        end
      end
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = youlve.name,
        cancelable = false,
      })
    end
  end,
})

return youlve
