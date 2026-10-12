local zhuoyue = fk.CreateSkill{
  name = "zhuoyue",
}

Fk:loadTranslationTable{
  ["zhuoyue"] = "酌乐",
  [":zhuoyue"] = "当你成为非伤害类牌的目标后（非因此技能），你可以令一名角色视为使用【酒】。"..
    "处于【酒】状态的角色成为伤害牌目标后，你可以移除其【酒】状态并令其视为使用【桃】。",

  ["#zhuoyue-invoke"] = "是否对%dest发动 酌乐，移除其【酒】状态并令其视为使用【桃】",
  ["#zhuoyue-choose"] = "是否发动 酌乐，令一名角色视为使用【酒】",

  ["$zhuoyue1"] = "",
  ["$zhuoyue2"] = "",
}

zhuoyue:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(zhuoyue.name) then return false end
    if data.card.is_damage_card then
      return not target.dead and target.drank > 0
    elseif player == target and not table.contains(data.card.skillNames, zhuoyue.name) then
      local room = player.room
      local analeptic = Fk:cloneCard("analeptic")
      analeptic.skillName = zhuoyue.name
      return table.find(room.alive_players, function(p)
        return p:canUse(analeptic)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local skillName = zhuoyue.name
    local room = player.room
    if data.card.is_damage_card then
      if room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#zhuoyue-invoke::" .. target.id }) then
        event:setCostData(self, { tos = { target } })
        return true
      end
    else
      local analeptic = Fk:cloneCard("analeptic")
      analeptic.skillName = skillName
      local targets = table.filter(room.alive_players, function (p)
        return p:canUse(analeptic)
      end)
      targets = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhuoyue-choose",
          skill_name = skillName,
        }
      )
      if #targets > 0 then
        event:setCostData(self, { tos = targets })
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local skillName = zhuoyue.name
    local room = player.room
    if data.card.is_damage_card then
      target.drank = 0
      room:broadcastProperty(target, "drank")
      local peach = Fk:cloneCard("peach")
      peach.skillName = skillName
      if target:canUse(peach) then
        room:useCard(
          {
            from = target,
            card = peach,
            tos = { target }
          }
        )
      end
    else
      --不二检
      ---@type ServerPlayer
      local to = event:getCostData(self).tos[1]
      local analeptic = Fk:cloneCard("analeptic")
      analeptic.skillName = skillName
      room:useCard(
        {
          from = to,
          card = analeptic,
          tos = { to },
        }
      )
    end
  end,
})

return zhuoyue
