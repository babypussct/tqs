local jishan = fk.CreateSkill {
  name = "m_js__jishan",
}

Fk:loadTranslationTable{
  ["m_js__jishan"] = "积善",
  [":m_js__jishan"] = "每回合各限一次，当一名角色受到伤害时，你可以失去2点体力并防止此伤害，然后你与其各摸一张牌；"..
  "当你造成伤害后，你可以令一名体力值最小且以此法被防止过伤害的角色回复1点体力。",

  ["#m_js__jishan-invoke"] = "积善：你可以失去2点体力防止 %dest 受到的伤害，并与其各摸一张牌",
  ["#m_js__jishan-choose"] = "积善：你可以令一名角色回复1点体力",

  ["$m_js__jishan1"] = "刀兵罪在我，而百姓何辜耶？",
  ["$m_js__jishan2"] = "备宁愿一死，只求百姓得安！",
  ["$m_js__jishan3"] = "民若得安，则天下安矣！",
  ["$m_js__jishan4"] = "勿以恶小而为之，勿以善小而不为！",
}

jishan:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jishan.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jishan.name,
      prompt = "#m_js__jishan-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:addTableMarkIfNeed(player, "m_js__jishan_record", target.id)
    room:loseHp(player, 2, jishan.name)
    if not player.dead then
      player:drawCards(1, jishan.name)
    end
    if not target.dead then
      target:drawCards(1, jishan.name)
    end
  end,
})

jishan:addEffect(fk.Damage, {
  anim_type = "support",
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jishan.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function(to)
        return table.contains(player:getTableMark("m_js__jishan_record"), to.id) and to:isWounded() and
          table.every(player.room.alive_players, function(p)
            return p.hp >= to.hp
          end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(to)
      return table.contains(player:getTableMark("m_js__jishan_record"), to.id) and to:isWounded() and
        table.every(room.alive_players, function(p)
          return p.hp >= to.hp
        end)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_js__jishan-choose",
      skill_name = jishan.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = event:getCostData(self).tos[1],
      num = 1,
      recoverBy = player,
      skillName = jishan.name,
    }
  end,
})

return jishan
