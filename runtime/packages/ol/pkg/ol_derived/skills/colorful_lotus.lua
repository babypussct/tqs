local skill = fk.CreateSkill {
  name = "#colorful_lotus_skill",
  tags = { Skill.Compulsory },
  attached_equip = "colorful_lotus",
}

Fk:loadTranslationTable{
  ["#colorful_lotus_skill"] = "彩莲",
}

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) then
      local damage_events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function (e)
        return e.data.from == player
      end, Player.HistoryRound)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

skill:addEffect(fk.PreHpRecover, {
  can_trigger = function(self, event, target, player, data)
    if data.recoverBy == player and player:hasSkill(skill.name) then
      local recover_events = player.room.logic:getEventsOfScope(GameEvent.Recover, 1, function (e)
        return e.data.recoverBy == player
      end, Player.HistoryTurn)
      return #recover_events == 1 and recover_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeRecover(1)
  end,
})

skill:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    if player:hasSkill(skill.name) then
      for _, equip in ipairs(player:getEquipCards()) do
        if table.contains(equip:getEquipSkills(player) or {}, Fk.skills[skill.name]) and
          equip:compareSuitWith(card) then
          return true
        end
      end
    end
  end,
})

return skill
