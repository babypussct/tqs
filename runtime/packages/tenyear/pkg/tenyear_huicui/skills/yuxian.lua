local yuxian = fk.CreateSkill {
  name = "yuxian",
}

Fk:loadTranslationTable{
  ["yuxian"] = "育贤",
  [":yuxian"] = "每轮开始时，你可以依次选择至多4张手牌展示并记录花色，"..
  "其他角色回合该角色使用前4张牌时，每有1张牌与你记录花色相同且对应顺序，你可与其各摸一张牌。",
  ["#yuxian-invoke"] = "育贤：你可以与 %dest 各摸一张牌",
  ["#yuxian-choose"] = "育贤：展示至多4张手牌，并按顺序记录花色",
  ["@[suits]yuxian-round"] = "育贤",

  ["$yuxian1"] = "建业风寒，登儿益常添衣。",
  ["$yuxian2"] = "妾不为汝妻，尚不能为人母乎？",
}

yuxian:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuxian.name) and data.card.suit ~= Card.NoSuit then
      if target == player.room.current and player:getMark("@[suits]yuxian-round") ~= 0 and not target.dead and target ~= player then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 4, function(e)
          local use = e.data
          return use.from == target
        end, Player.HistoryTurn)
        local index = table.indexOf(use_events, player.room.logic:getCurrentEvent())
        return index ~= -1 and data.card.suit == player:getTableMark("@[suits]yuxian-round")[index]
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = yuxian.name,
      prompt = "#yuxian-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yuxian.name)
    if not target.dead then
      target:drawCards(1, yuxian.name)
    end
  end,
})
yuxian:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuxian.name) and not player:isKongcheng() 
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 4,
      include_equip = false,
      skill_name = yuxian.name,
      prompt = "#yuxian-choose",
      cancelable = true,
    }) 
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    for i = 1, #cards, 1 do
      room:addTableMark(player, "@[suits]yuxian-round", Fk:getCardById(cards[i]).suit)
    end
    player:showCards(cards)
  end,
})


yuxian:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[suits]yuxian-round", 0)
end)

return yuxian
