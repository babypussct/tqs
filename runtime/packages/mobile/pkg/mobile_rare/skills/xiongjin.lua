local xiongjin = fk.CreateSkill {
  name = "xiongjin",
}

Fk:loadTranslationTable {
  ["xiongjin"] = "雄进",
  [":xiongjin"] = "每轮各限一次，你/其他角色的出牌阶段开始时，你可以令你/其摸X张牌（X为你已损失的体力值，且至少为1，至多为3）。" ..
      "若如此做，本回合的弃牌阶段开始时，你/其弃置所有非基本/基本牌。",
  ["#xiongjin_discard"] = "雄进",

  ["#xiongjinUser-invoke"] = "雄进：你可摸%arg张牌，于此回合弃牌阶段开始时弃置所有非基本牌",
  ["#xiongjinAnother-invoke"] = "雄进：你可令%dest摸%arg张牌，其于此回合弃牌阶段开始时弃置所有基本牌",
  ["@@xiongjinBasic-turn"] = "雄进 弃基本牌",
  ["@@xiongjinNotBasic-turn"] = "雄进 弃非基本",

  ["$xiongjin1"] = "将者当有勇有谋，屡战屡胜。",
  ["$xiongjin2"] = "逆贼造乱，此吾等建功之时。",
}

xiongjin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiongjin.name) and target.phase == Player.Play and
        player:getMark(target == player and "xiongjinUser-round" or "xiongjinAnother-round") == 0 and
        not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = target == player and "#xiongjinUser-invoke::" or "#xiongjinAnother-invoke::" .. target.id
    local drawNum = math.max(1, player:getLostHp())
    if room:askToSkillInvoke(player, {
          skill_name = xiongjin.name,
          prompt = prompt .. ":" .. math.min(3, drawNum)
        }) then
      room:setPlayerMark(player, target == player and "xiongjinUser-round" or "xiongjinAnother-round", 1)
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target.dead then return end
    local drawNum = math.max(1, player:getLostHp())
    drawNum = math.min(3, drawNum)
    if drawNum > 0 then
      target:drawCards(drawNum, xiongjin.name)
    end
    room:addTableMarkIfNeed(target, target == player and "@@xiongjinNotBasic-turn" or "@@xiongjinBasic-turn", player.id)
  end,
})

xiongjin:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and
        ((#player:getTableMark("@@xiongjinNotBasic-turn") ~= 0 and player.room:getPlayerById(player:getTableMark("@@xiongjinNotBasic-turn")[1]):hasSkill(xiongjin.name))
          or (#player:getTableMark("@@xiongjinBasic-turn") ~= 0 and player.room:getPlayerById(player:getTableMark("@@xiongjinBasic-turn")[1]):hasSkill(xiongjin.name)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@xiongjinBasic-turn") ~= 0 then
      local cards = table.filter(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).type == Card.TypeBasic
      end)
      if #cards > 0 then
        room:throwCard(cards, xiongjin.name, player, player)
      end
    end
    if player:getMark("@@xiongjinNotBasic-turn") ~= 0 then
      local cards = table.filter(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).type ~= Card.TypeBasic
      end)

      if #cards > 0 then
        room:throwCard(cards, xiongjin.name, player, player)
      end
    end
  end,
})

xiongjin:addLoseEffect(function(self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@xiongjinBasic-turn", player.id)
    room:removeTableMark(p, "@@xiongjinNotBasic-turn", player.id)
  end
end)

return xiongjin
