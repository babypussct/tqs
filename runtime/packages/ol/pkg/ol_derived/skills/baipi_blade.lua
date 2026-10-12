local skill = fk.CreateSkill {
  name = "#baipi_blade_skill",
  attached_equip = "baipi_blade",
}

Fk:loadTranslationTable{
  ["#baipi_blade_skill"] = "百辟刀",

  ["#baipi_blade_skill-invoke"] = "百辟刀：你可以获得 %dest 的一张手牌",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card and
      data.card.trueName == "slash" and
      data.by_user and
      player:hasSkill(skill.name) and
      player ~= data.to and
      data.to:isAlive() and
      not data.to:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      { skill_name = skill.name, prompt = "#baipi_blade_skill-invoke::" .. data.to.id }
    )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(
      player,
      {
        target = data.to,
        flag = "h",
        skill_name = skill.name,
      }
    )

    room:obtainCard(player, id, false, fk.ReasonPrey, player, skill.name)
  end,
})

return skill
