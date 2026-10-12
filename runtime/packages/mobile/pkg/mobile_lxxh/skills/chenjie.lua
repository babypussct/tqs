local chenjie = fk.CreateSkill {
  name = "mobile__chenjie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__chenjie"] = "臣节",
  [":mobile__chenjie"] = "锁定技，若你有〖蹒襄〗，当一名成为过蹒襄目标的角色死亡后，你弃置你区域内所有牌，然后摸四张牌。",

  ["$mobile__chenjie1"] = "杀陛下者，臣之罪也！",
  ["$mobile__chenjie2"] = "身为魏臣，终不背魏。",
}

chenjie:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenjie.name) and player:hasSkill("panxiang", true) and
      player:getMark("panxiang_"..target.id) ~= 0
  end,
  on_use = function(self, event, target, player, data)
    player:throwAllCards("hej", chenjie.name)
    if not player.dead then
      player:drawCards(4, chenjie.name)
    end
  end,
})

return chenjie
