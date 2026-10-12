local dulu = fk.CreateSkill({
  name = "dulu",
})

Fk:loadTranslationTable{
  ["dulu"] = "妒戮",
  [":dulu"] = "出牌阶段限一次，你可以对任意名对你使用过牌的其他角色各造成1点伤害并随机弃置其一张手牌，然后直到你的下个回合结束，"..
  "其进入濒死状态时，你获得其所有黑色牌。",

  ["#dulu"] = "妒戮：对任意名角色造成1点伤害并随机弃置其一张手牌，其进入濒死状态时获得其所有黑色牌",

  ["$dulu1"] = "本初已死，是非对错我已无心分辨。",
  ["$dulu2"] = "没了这头黑丝，看阎王收不收你这丑奴！",
}

dulu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#dulu",
  max_phase_use_time = 1,
  card_num = 0,
  min_target_num = 1,
  can_use = function (self, player)
    return player:usedEffectTimes(dulu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return table.contains(player:getTableMark(dulu.name), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = effect.tos
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if player:isAlive() and p:isAlive() then
        local id
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if turn_event then
          id = turn_event.id
        else
          id = room.logic:getCurrentEvent().id
        end
        room:setPlayerMark(player, "dulu_"..tostring(p.id), id)
      end

      if p:isAlive() and not p:isKongcheng() then
        room:throwCard(room:tableRandomPick(p:getCardIds("h")), dulu.name, p, player)
      end

      if p:isAlive() then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = dulu.name,
        }
      end
    end
  end,
})

dulu:addEffect(fk.EnterDying, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(dulu.name) and player:getMark("dulu_"..tostring(target.id)) ~= 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {target} })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(target:getCardIds("he"), function (id)
      return Fk:getCardById(id).color == Card.Black
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, dulu.name, nil, false, player)
    end
  end,
})

dulu:addEffect(fk.TurnEnd, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local id = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true).id
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if player:getMark("dulu_"..tostring(p.id)) < id then
        room:setPlayerMark(player, "dulu_"..tostring(p.id), 0)
      end
    end
  end,
})

dulu:addEffect(fk.TargetConfirmed, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(dulu.name, true) and data.from ~= player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, dulu.name, data.from)
  end,
})

dulu:addAcquireEffect(function (self, player)
  local room = player.room
  local enemies = {}
  room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
    local use = e.data
    if use.from ~= player and table.contains(use.tos, player) then
      table.insertIfNeed(enemies, use.from)
    end
  end, Player.HistoryGame)
  room:setPlayerMark(player, dulu.name, enemies)
end)

return dulu
