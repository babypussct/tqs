local yixiang = fk.CreateSkill{
  name = "yixiang",
}

Fk:loadTranslationTable{
  ["yixiang"] = "义襄",
  [":yixiang"] = "每回合限一次，当你成为一名体力值大于你的角色使用牌的目标后，你可以从牌堆中随机获得一张你没有的基本牌。",

  ["$yixiang1"] = "一方有难，八方应援。",
  ["$yixiang2"] = "昔日有恩，还望此时来报。",
}

yixiang:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yixiang.name) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      data.from.hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    local ids = table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).type == Card.TypeBasic and not table.contains(names, Fk:getCardById(id).trueName)
    end)
    if #ids > 0 then
      room:obtainCard(player, room:tableRandomPick(ids), false, fk.ReasonJustMove, player, yixiang.name)
    end
  end,
})

return yixiang
