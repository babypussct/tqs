local kangkai = fk.CreateSkill {
  name = "ofl_heg__kangkai",
}

Fk:loadTranslationTable{
  ["ofl_heg__kangkai"] = "慷忾",
  [":ofl_heg__kangkai"] = "你与其距离不大于1的角色成为【杀】的目标后，若该角色：为你，你可以摸一张牌；不为你，你可以展示一张牌并交给该角色，"..
  "若为装备牌，其可以使用之。",

  ["#ofl_heg__kangkai-draw"] = "慷忾：你可以摸一张牌",
  ["#ofl_heg__kangkai-give"] = "慷忾：你可以展示并交给 %dest 一张牌，若为装备牌其可以使用",
  ["#ofl_heg__kangkai-use"] = "慷忾：你可以使用%arg",

  ["$ofl_heg__kangkai1"] = "典将军，比比看谁杀敌更多！",
  ["$ofl_heg__kangkai2"] = "父亲快走，有我殿后！"
}

kangkai:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(kangkai.name) and data.card.trueName == "slash" then
      if target == player then
        return true
      else
        return player:distanceTo(target) <= 1
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    event:setCostData(self, { tos = {target} })
    if target == player then
      return room:askToSkillInvoke(player, {
        skill_name = kangkai.name,
        prompt = "#ofl_heg__kangkai-draw",
      })
    else
      local card = room:askToCards(player, {
        skill_name = kangkai.name,
        min_num = 1,
        max_num = 1,
        prompt = "#ofl_heg__kangkai-give::"..target.id,
        include_equip = true,
        cancelable = true,
      })
      if #card > 0 then
        event:setCostData(self, { tos = {target}, cards = card })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      player:drawCards(1, kangkai.name)
    else
      local card = (event:getCostData(self).cards or {})[1]
      if table.contains(player:getCardIds("h"), card) then
        player:showCards(card)
      else
        room:showCards(card)
      end
      if player.dead or target.dead or not table.contains(player:getCardIds("he"), card) then return end
      room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, kangkai.name, nil, true, player)
      if not table.contains(target:getCardIds("h"), card) or target.dead then return end
      if Fk:getCardById(card).type == Card.TypeEquip then
        room:askToUseRealCard(target, {
          pattern = {card},
          skill_name = kangkai.name,
          prompt = "#ofl_heg__kangkai-use:::"..Fk:getCardById(card):toLogString(),
        })
      end
    end
  end,
})

return kangkai
