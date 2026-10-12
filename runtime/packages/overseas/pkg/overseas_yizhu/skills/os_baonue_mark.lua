local osBaonueMark = fk.CreateSkill {
  name = "#os__baonue_mark",
}

Fk:loadTranslationTable{
  ["@os__baonue"] = "暴虐值",
}

local spec = {
  priority = 3,
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      table.find(player:getSkillNameList(), function(skill)
        return (Fk.skill_skels[skill] or {}).os__baonue
      end) and player:getMark("@os__baonue") < 5
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__baonue")
  end,
}
osBaonueMark:addEffect(fk.Damage, spec)
osBaonueMark:addEffect(fk.Damaged, spec)

osBaonueMark:addEffect(fk.EventLoseSkill, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@os__baonue") > 0 and
      not table.find(player:getSkillNameList(), function(skill)
        return (Fk.skill_skels[skill] or {}).os__baonue
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@os__baonue", 0)
  end,
})

return osBaonueMark
