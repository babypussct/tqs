local guying = fk.CreateSkill{
  name = "ty__guying",
}

Fk:loadTranslationTable{
  ["ty__guying"] = "固营",
  [":ty__guying"] = "结束阶段，你可以选择一名角色，直到你下个结束阶段开始前：当其下一次受到伤害后，摸体力上限张牌（最多摸5张），"..
  "然后将超出体力上限的手牌交给你。若在此期间没有触发此效果，则你下次发动〖固营〗时可以多选择一名角色。",

  ["#ty__guying-choose"] = "固营：选择%arg名角色，其下次受到伤害后摸体力上限张牌，并将超出体力上限的牌数交给你",
  ["@@ty__guying"] = "固营",
  ["#ty__guying-give"] = "固营：请将%arg张手牌交给 %src",

  ["$ty__guying1"] = "孤石逆潮，暂挽大浪将倾。",
  ["$ty__guying2"] = "深垒为营，何惧江东宵小。",
}

guying:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(guying.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1 + player:getMark("ty__guying_extra"),
      targets = room.alive_players,
      skill_name = guying.name,
      prompt = "#ty__guying-choose:::"..(1 + player:getMark("ty__guying_extra")),
      cancelable = true,
    })
    room:setPlayerMark(player, "ty__guying_extra", 0)
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    room:setPlayerMark(player, guying.name, table.map(tos, Util.IdMapper))
    for _, p in ipairs(tos) do
      room:addPlayerMark(p, "@@ty__guying", 1)
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(guying.name) and player.phase == Player.Finish
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark(guying.name) ~= 0 then
      for _, id in ipairs(player:getTableMark(guying.name)) do
        local p = room:getPlayerById(id)
        room:removePlayerMark(p, "@@ty__guying", 1)
      end
      room:setPlayerMark(player, "ty__guying_extra", 1)
      room:setPlayerMark(player, guying.name, 0)
    end
  end,
})

guying:addEffect(fk.Damaged, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.contains(player:getTableMark(guying.name), target.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, guying.name, target.id)
    if target.dead then return end
    room:removePlayerMark(target, "@@ty__guying", 1)
    target:drawCards(math.min(target.maxHp, 5), guying.name)
    if target == player or target.dead or player.dead or target:getHandcardNum() <= target.maxHp then return end
    local n = target:getHandcardNum() - target.maxHp
    local cards = room:askToCards(target, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = guying.name,
      prompt = "#ty__guying-give:"..player.id.."::"..n,
      cancelable = false,
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, guying.name, nil, false, target)
  end,
})

guying:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getTableMark(guying.name)) do
    local p = room:getPlayerById(id)
    room:removePlayerMark(p, "@@ty__guying", 1)
  end
  room:setPlayerMark(player, "ty__guying_extra", 0)
  room:setPlayerMark(player, guying.name, 0)
end)

return guying
