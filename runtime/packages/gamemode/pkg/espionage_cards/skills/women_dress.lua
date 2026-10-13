local skill = fk.CreateSkill {
  name = "#women_dress_skill",
  tags = { Skill.Compulsory },
  attached_equip = "women_dress",
}

Fk:loadTranslationTable{
  ["#women_dress_skill"] = "女装",
}

skill:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      player:isMale() and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = skill.name,
      pattern = ".|.|black",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return skill
