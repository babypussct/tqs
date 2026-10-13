local pigua = fk.CreateSkill {
  name = "jiange__pigua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__pigua"] = "披挂",
  [":jiange__pigua"] = "锁定技，准备阶段，若你的装备区没有牌，你失去1点体力，然后从牌堆或弃牌堆随机获得一张装备牌。",
}

pigua:addEffect(fk.EventPhaseStart, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pigua.name) and player.phase == Player.Start and
      #player:getCardIds("e") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, pigua.name)
    if player.dead then return end
    local id = room:getCardsFromPileByRule(".|.|.|.|.|equip", 1, "allPiles")
    if #id > 0 then
      room:obtainCard(player, id, false, fk.ReasonJustMove, player, pigua.name)
    end
  end,
})

return pigua
