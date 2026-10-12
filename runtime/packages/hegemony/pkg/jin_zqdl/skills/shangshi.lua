local shangshi = fk.CreateSkill{
  name = "heg__shangshi",
}

Fk:loadTranslationTable{
  ["heg__shangshi"] = "伤逝",
  [":heg__shangshi"] = "每名角色的回合结束时，你可以将手牌摸至已损失体力值。",

  ["$heg__shangshi1"] = "伤我最深的，竟是你司马懿。",
  ["$heg__shangshi2"] = "世间刀剑数万，何以情字伤人？",
}

shangshi:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shangshi.name) and player:getHandcardNum() < player:getLostHp()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), shangshi.name)
  end,
})

shangshi:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return shangshi

