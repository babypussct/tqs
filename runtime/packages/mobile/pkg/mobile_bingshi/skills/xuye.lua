local xuye = fk.CreateSkill {
  name = "xuye",
}

Fk:loadTranslationTable{
  ["xuye"] = "蓄业",
  [":xuye"] = "每回合限一次，当全场手牌数最少的角色受到伤害后，你可以令其摸两张牌，然后若其手牌数全场最多，你将其区域内的一张牌置于牌堆顶。",

  ["#xuye-invoke"] = "蓄业：你可以令 %dest 摸两张牌，然后若其手牌数全场最多，你将其区域内一张牌置于牌堆顶",
  ["#xuye-ask"] = "蓄业：将 %dest 区域内一张牌置于牌堆顶",

  ["$xuye1"] = "今世宜须兵卫，且召汉昌賨民为兵。",
  ["$xuye2"] = "今天下扰乱，治下岂可无人？",
  ["$xuye3"] = "募兵但为御敌，岂敢怀有贰心？",
}

xuye:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(xuye.name) and not target.dead and
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= target:getHandcardNum()
      end) and
      player:usedSkillTimes(xuye.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xuye.name,
      prompt = "#xuye-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    target:drawCards(2, xuye.name)
    if player.dead or target.dead or target:isAllNude() then return end
    if table.every(room.alive_players, function (p)
        return p:getHandcardNum() <= target:getHandcardNum()
      end) then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "hej",
        skill_name = xuye.name,
        prompt = "#xuye-ask::"..target.id,
      })
      room:moveCards({
        ids = {card},
        from = target,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = xuye.name,
        proposer = player,
        moveVisible = false,
        drawPilePosition = 1,
      })
    end
  end,
})

return xuye
