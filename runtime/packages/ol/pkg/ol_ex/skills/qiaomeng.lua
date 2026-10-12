
local qiaomeng = fk.CreateSkill{
  name = "ol_ex__qiaomeng",
}

Fk:loadTranslationTable{
  ["ol_ex__qiaomeng"] = "趫猛",
  [":ol_ex__qiaomeng"] = "当你使用【杀】对一名角色造成伤害后，你可以弃置其区域里的一张牌。若此牌为坐骑牌，你获得之。",

  ["#ol_ex__qiaomeng-invoke"] = "趫猛：你可以弃置 %dest 区域内一张牌，若为坐骑牌则获得之",

  ["$ol_ex__qiaomeng1"] = "夺敌辎重，以为己用。",
  ["$ol_ex__qiaomeng2"] = "秣马厉兵，枕戈待战。",
}

qiaomeng:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaomeng.name) and
      data.card and data.card.trueName == "slash" and
      not data.to:isAllNude()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = qiaomeng.name,
      prompt = "#ol_ex__qiaomeng-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card
    if data.to == player then
      local ids = table.filter(player:getCardIds("hej"), function (id)
        return not player:prohibitDiscard(id)
      end)
      if #ids == 0 then return end
      card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = qiaomeng.name,
        pattern = tostring(Exppattern{ id = ids }),
        cancelable = false,
        expand_pile = player:getCardIds("j"),
      })[1]
    else
      card = room:askToChooseCard(player, {
        target = data.to,
        flag = "hej",
        skill_name = qiaomeng.name,
      })
    end
    local yes = Fk:getCardById(card).sub_type == Card.SubtypeOffensiveRide or Fk:getCardById(card).sub_type == Card.SubtypeDefensiveRide
    room:throwCard(card, qiaomeng.name, data.to, player)
    if yes and table.contains(room.discard_pile, card) and not player.dead then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, qiaomeng.name, nil, true, player)
    end
  end,
})

return qiaomeng
