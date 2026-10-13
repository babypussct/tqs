local skill = fk.CreateSkill {
  name = "#mobile_seal_skill",
  attached_equip = "mobile_seal",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["#mobile_seal_skill"] = "传国玉玺",
}

skill:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
    player:drawCards(1, skill.name)
    if not player.dead and player.role ~= "lord" then
      room:loseHp(player, 1, skill.name)
    end
  end,
})

return skill
