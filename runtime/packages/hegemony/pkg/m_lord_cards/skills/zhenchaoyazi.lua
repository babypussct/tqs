
local skill = fk.CreateSkill{
  name = "#zhenchaoyazi_skill",
  attached_equip = "zhenchaoyazi",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and not data.from:isNude() then
      if (player.faceup and not data.from.faceup) or (not player.faceup and data.from.faceup) then
        return true
      end
      if (player.chained and not data.from.chained) or (not player.chained and data.from.chained) then
        return true
      end
      if player.general == "anjiang" or player.deputyGeneral == "anjiang" then
        return data.from.general ~= "anjiang" and data.from.deputyGeneral ~= "anjiang"
      else
        return data.from.general == "anjiang" or data.from.deputyGeneral == "anjiang"
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill.name,
      cancelable = false,
    })
  end,
})

return skill
