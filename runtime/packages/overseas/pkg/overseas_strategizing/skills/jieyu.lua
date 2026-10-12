local jieyu = fk.CreateSkill {
  name = "os__jieyu",
}

Fk:loadTranslationTable{
  ["os__jieyu"] = "竭御",
  [":os__jieyu"] = "每轮限一次，结束阶段或每轮第一次受到伤害后，你可以弃置所有手牌，然后从弃牌堆中获得不同牌名的基本牌各一张。",

  ["#os__jieyu-invoke"] = "竭御：你可以弃置所有手牌，从弃牌堆中获得不同牌名的基本牌各一张",

  ["$os__jieyu1"] = "葭萌，蜀之咽喉，峻必竭力守之。",
  ["$os__jieyu2"] = "吾头可得，城不可得。",
}

local spec = {
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jieyu.name,
      prompt = "#os__jieyu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h", jieyu.name)
    if player.dead then return end
    local mapper = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        mapper[card.trueName] = mapper[card.trueName] or {}
        table.insert(mapper[card.trueName], id)
      end
    end
    local cards = {}
    for _, ids in pairs(mapper) do
      table.insert(cards, room:tableRandomPick(ids))
    end
    if #cards > 0 then
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, jieyu.name)
    end
  end,
}

jieyu:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyu.name) and player.phase == Player.Finish and
      player:usedSkillTimes(jieyu.name, Player.HistoryRound) == 0 and not player:isKongcheng()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

jieyu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jieyu.name) and
      player:usedSkillTimes(jieyu.name, Player.HistoryRound) == 0 and not player:isKongcheng() then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end, Player.HistoryRound)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return jieyu
