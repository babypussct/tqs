local xiongjin = fk.CreateSkill {
  name = "os__xiongjin",
}

Fk:loadTranslationTable{
  ["os__xiongjin"] = "雄进",
  [":os__xiongjin"] = "每轮各限一次，你/其他角色的出牌阶段开始时，你可以令你/其摸X张牌（X为你已损失的体力值，且至少为1，至多为4）。" ..
  "若如此做，本回合的弃牌阶段开始时，你/其弃置所有非基本/基本牌。",

  ["#os__xiongjin_user-invoke"] = "雄进：摸%arg张牌，弃牌阶段开始时弃置所有非基本牌",
  ["#os__xiongjin_another-invoke"] = "雄进：令 %dest 摸%arg张牌，弃牌阶段开始时其弃置所有基本牌",
  ["@@os__xiongjin_basic-turn"] = "雄进 弃基本牌",
  ["@@os__xiongjin_nonbasic-turn"] = "雄进 弃非基本",

  ["$os__xiongjin1"] = "将者当有勇有谋，屡战屡胜。",
  ["$os__xiongjin2"] = "逆贼造乱，此吾等建功之时。",
}

xiongjin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiongjin.name) and target.phase == Player.Play and
      player:getMark(target == player and "os__xiongjin_user-round" or "os__xiongjin_another-round") == 0 and
      not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = target == player and "#os__xiongjin_user-invoke::" or "#os__xiongjin_another-invoke::" .. target.id
    local drawNum = math.max(1, player:getLostHp())
    if room:askToSkillInvoke(player, {
      skill_name = xiongjin.name,
      prompt = prompt..":"..math.min(4, drawNum)
    }) then
      room:setPlayerMark(player, target == player and "os__xiongjin_user-round" or "os__xiongjin_another-round", 1)
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target.dead then return end
    local drawNum = math.max(1, player:getLostHp())
    drawNum = math.min(4, drawNum)
    if drawNum > 0 then
      target:drawCards(drawNum, xiongjin.name)
    end
    room:addTableMarkIfNeed(target, target == player and "@@os__xiongjin_nonbasic-turn" or "@@os__xiongjin_basic-turn", player.id)
  end,
})

xiongjin:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and
      (player:getMark("@@os__xiongjin_basic-turn") ~= 0 or player:getMark("@@os__xiongjin_nonbasic-turn") ~= 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@os__xiongjin_basic-turn") ~= 0 then
      local cards = table.filter(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).type == Card.TypeBasic
      end)
      if #cards > 0 then
        room:throwCard(cards, xiongjin.name, player, player)
      end
    end
    if player:getMark("@@os__xiongjin_nonbasic-turn") ~= 0 then
      local cards = table.filter(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).type ~= Card.TypeBasic
      end)

      if #cards > 0 then
        room:throwCard(cards, xiongjin.name, player, player)
      end
    end
  end,
})

xiongjin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@os__xiongjin_basic-turn", player.id)
    room:removeTableMark(p, "@@os__xiongjin_nonbasic-turn", player.id)
  end
end)

return xiongjin
