local guanxing = fk.CreateSkill{
  name = "ld__guanxing",
}
guanxing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guanxing.name) and
      player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToGuanxing(player, {cards = room:getNCards(math.min(5, #room.alive_players))})
  end,
})

Fk:loadTranslationTable{
  ["ld__guanxing"] = "观星",
  [":ld__guanxing"] = "准备阶段，你可将牌堆顶的X张牌（X为角色数且至多为5}）扣置入处理区（对你可见），你将其中任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。",

  ["$ld__guanxing1"] = "天文地理，丞相所教，维铭记于心。",
  ["$ld__guanxing2"] = "哪怕只有一线生机，我也不会放弃！",
}

return guanxing
