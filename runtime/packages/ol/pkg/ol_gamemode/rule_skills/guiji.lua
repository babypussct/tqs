local guiji = fk.CreateSkill{
  name = "boss__guiji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["boss__guiji"] = "诡计",
  [":boss__guiji"] = "锁定技，准备阶段，若你的判定区内有牌，随机弃置其中一张牌。",
}

guiji:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guiji.name) and player.phase == Player.Start and
      #player:getCardIds("j") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(room:tableRandomPick(player:getCardIds("j")), guiji.name, player, player)
  end,
})

return guiji
