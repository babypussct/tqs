
local jianchu = fk.CreateSkill{
  name = "jianchu",
}

Fk:loadTranslationTable{
  ["jianchu"] = "鞬出",
  [":jianchu"] = "当你使用【杀】指定目标后，你可以弃置目标角色一张牌，若此牌：为装备牌，其不能使用【闪】响应此【杀】；不为装备牌，其获得此【杀】。",

  ["#jianchu-invoke"] = "鞬出：你可以弃置 %dest 一张牌，若为装备牌其不能响应，不为装备牌其获得此【杀】",

  ["$jianchu1"] = "你，可敢挡我！",
  ["$jianchu2"] = "我要杀你们个片甲不留！",
}

jianchu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianchu.name)and
      data.card.trueName == "slash" and not data.to:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jianchu.name,
      prompt = "#jianchu-invoke:"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = jianchu.name,
    })
    room:throwCard(id, jianchu.name, data.to, player)
    local card = Fk:getCardById(id)
    if card.type == Card.TypeEquip then
      data.disresponsive = true
    else
      if not data.to.dead and room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, data.to, fk.ReasonJustMove, jianchu.name, nil, true, data.to)
      end
    end
  end,
})

return jianchu
