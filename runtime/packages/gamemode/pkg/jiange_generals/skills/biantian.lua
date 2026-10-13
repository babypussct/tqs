local biantian = fk.CreateSkill {
  name = "jiange__biantian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__biantian"] = "变天",
  [":jiange__biantian"] = "锁定技，准备阶段，你进行一次判定，若结果为：<br>红色，所有敌方进入狂风状态（若天侯孔明在场，受到火焰伤害+1），"..
  "直到你下回合开始；<br>♠，所有友方进入大雾状态（若天侯孔明在场，受到非雷电伤害时，防止此伤害），直到你下回合开始。",
}

biantian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biantian.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = biantian.name,
      pattern = ".|.|^club",
    }
    room:judge(judge)
    if player.dead then return end
    local mark = {}
    if judge.card.color == Card.Red then
      for _, p in ipairs(player:getEnemies()) do
        room:doIndicate(player, {p})
        room:addPlayerMark(p, "@@kuangfeng", 1)
        room:addSkill("aux_kuangfeng")
        table.insert(mark, p.id)
      end
      room:setPlayerMark(player, "jiange__biantian_kuangfeng", mark)
    elseif judge.card.suit == Card.Spade then
      for _, p in ipairs(player:getFriends()) do
        room:doIndicate(player, {p})
        room:addPlayerMark(p, "@@dawu", 1)
        room:addSkill("aux_dawu")
        table.insert(mark, p.id)
      end
      room:setPlayerMark(player, "jiange__biantian_dawu", mark)
    end
  end,
})

biantian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("jiange__biantian_kuangfeng") ~= 0 or player:getMark("jiange__biantian_dawu") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("jiange__biantian_kuangfeng") ~= 0 then
      for _, id in ipairs(player:getTableMark("jiange__biantian_kuangfeng")) do
        local p = room:getPlayerById(id)
        room:removePlayerMark(p, "@@kuangfeng", 1)
      end
      room:setPlayerMark(player, "jiange__biantian_kuangfeng", 0)
    end
    if player:getMark("jiange__biantian_dawu") ~= 0 then
      for _, id in ipairs(player:getTableMark("jiange__biantian_dawu")) do
        local p = room:getPlayerById(id)
        room:removePlayerMark(p, "@@dawu", 1)
      end
      room:setPlayerMark(player, "jiange__biantian_dawu", 0)
    end
  end,
})

return biantian
