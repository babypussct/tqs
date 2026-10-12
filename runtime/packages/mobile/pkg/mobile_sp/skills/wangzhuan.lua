local wangzhuan = fk.CreateSkill {
  name = "wangzhuan",
}

Fk:loadTranslationTable{
  ["wangzhuan"] = "妄专",
  [":wangzhuan"] = "当一名角色受到非游戏牌造成的伤害后，若你是伤害来源或受伤角色，你可以摸一张牌，然后当前回合角色本回合非锁定技失效。",

  ["#wangzhuan-invoke"] = "妄专：你可以摸一张牌，令当前回合角色本回合非锁定技无效",
  ["@@wangzhuan-turn"] = "妄专",

  ["$wangzhuan1"] = "此事若入君耳，后果汝当自知。",
  ["$wangzhuan2"] = "孙綝既诛，便是我一言之堂。",
}

wangzhuan:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wangzhuan.name) and not data.card and
      (data.from and data.from == player or target == player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wangzhuan.name,
      prompt = "#wangzhuan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, wangzhuan.name)
    if room.current and not room.current.dead then
      room:doIndicate(player, {room.current})
      room:addPlayerMark(room.current, "@@wangzhuan-turn")
      room:addPlayerMark(room.current, MarkEnum.UncompulsoryInvalidity .. "-turn")
    end
  end,
})

return wangzhuan
