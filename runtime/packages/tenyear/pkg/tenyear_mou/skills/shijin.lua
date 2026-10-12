local shijin = fk.CreateSkill {
  name = "shijin",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["shijin"] = "恃矜",
  [":shijin"] = "限定技，出牌阶段，若本回合你造成过伤害，你可以摸两张牌，"..
    "直至你的下个回合开始前你受到伤害时防止此伤害并摸一张牌，你的下个回合开始时弃置所有【杀】与锦囊牌并失去等量体力，"..
    "若你未因此流失体力此技能视为未发动过。",

  ["#shijin"] = "恃矜：摸两张牌，直到下回合开始获得效果",
  ["@@shijin"] = "恃矜",

  ["$shijin1"] = "哈哈哈哈，灭国擒主之功，古来几人？",
  ["$shijin2"] = "天下鼎立久矣，今吾折其一足！",
}

shijin:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#shijin",
  can_use = function(self, player)
    return player:usedSkillTimes(shijin.name, Player.HistoryGame) == 0 and player:getMark("shijin_damaged-turn") > 0
  end,
  target_num = 0,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(2, shijin.name)
    if player.dead then return end
    room:setPlayerMark(player, "@@shijin", 1)
  end,
})

shijin:addEffect(fk.StartPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(shijin.name) and player:usedSkillTimes(shijin.name, Player.HistoryGame) == 0 and
      player:getMark("shijin_damaged-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if #room.logic:getActualDamageEvents(1, function(e)
      return player == e.data.from
    end, Player.HistoryTurn) > 0 then
      room:setPlayerMark(player, "shijin_damaged-turn", 1)
    end
  end,
})

shijin:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shijin.name) and player:getMark("@@shijin") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local skillName = shijin.name
    player.room:notifySkillInvoked(player, self.name, "defensive")
    player:broadcastSkillInvoke(skillName)
    data:preventDamage()

    if player:isAlive() then
      player:drawCards(1, skillName)
    end
  end,
})

shijin:addEffect(fk.TurnStart, {
  anim_type = "special",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shijin.name) and player:getMark("shijin-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local skillName = shijin.name
    local room = player.room
    --只计算能被弃置的卡牌
    local cards = table.filter(player:getCardIds("h"), function (id)
      local c = Fk:getCardById(id)
      return (c.trueName == "slash" or c.type == Card.TypeTrick) and not player:prohibitDiscard(c)
    end)
    if #cards > 0 then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(skillName)
      room:throwCard(cards, skillName, player, player)
      if player.dead then return end
      room:loseHp(player, #cards, skillName)
    else
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(skillName)
      player:setSkillUseHistory(shijin.name, 0, Player.HistoryGame)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@@shijin") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@shijin", 0)
    room:setPlayerMark(player, "shijin-turn", 1)
  end
})

return shijin
