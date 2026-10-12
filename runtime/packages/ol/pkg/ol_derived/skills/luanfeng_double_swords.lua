local skill = fk.CreateSkill {
  name = "#luanfeng_double_swords_skill",
  attached_equip = "luanfeng_double_swords",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.card.name == "thunder__slash" or data.card.name == "fire__slash")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    if to:isNude() then
      player:drawCards(1, skill.name)
    else
      local result = room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skill.name,
        cancelable = true,
        prompt = "#luanfeng_double_swords-invoke:"..player.id,
      })
      if #result == 0 then
        player:drawCards(1, skill.name)
      end
    end
  end,
})

return skill
