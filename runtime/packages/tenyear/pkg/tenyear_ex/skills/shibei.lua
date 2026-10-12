local shibei = fk.CreateSkill {
  name = "ty_ex__shibei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__shibei"] = "矢北",
  [":ty_ex__shibei"] = "锁定技，你每回合受到第一次伤害后，你回复1点体力；你每回合受到第二次伤害后，你失去1点体力。",

  ["$ty_ex__shibei1"] = "主公在北，吾心亦在北！",
  ["$ty_ex__shibei2"] = "宁向北而死，不面南而生。",
}

shibei:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shibei.name) and
      player:usedSkillTimes(shibei.name, Player.HistoryTurn) < 2 then
      local damage_events = player.room.logic:getActualDamageEvents(2, function (e)
        return e.data.to == player
      end, Player.HistoryTurn)
      if damage_events[1].data == data then
        event:setCostData(self, { anim_type = "defensive" })
        return player:isWounded()
      elseif damage_events[2].data == data then
        event:setCostData(self, { anim_type = "negative" })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).anim_type
    if choice == "defensive" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = shibei.name,
      }
    else
      room:loseHp(player, 1, shibei.name)
    end
  end,
})

return shibei
