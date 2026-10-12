local jianchu = fk.CreateSkill {
  name = "m_ex__jianchu",
}

Fk:loadTranslationTable{
  ["m_ex__jianchu"] = "鞬出",
  [":m_ex__jianchu"] = "当你使用【杀】指定一个目标后，你可以弃置其一张牌，若此牌：为装备牌，其不能响应此【杀】；不为装备牌，该角色获得此【杀】。",

  ["$m_ex__jianchu1"] = "来啊！冲杀出去，杀他个片甲不留！",
  ["$m_ex__jianchu2"] = "一人一骑，横扫千军！",
}

jianchu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianchu.name) and
      data.card.trueName == "slash" and not data.to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = jianchu.name,
    })

    local card = Fk:getCardById(id)
    room:throwCard(id, jianchu.name, to, player)

    if card.type == Card.TypeEquip then
      data.disresponsive = true
    else
      if room:getCardArea(data.card) == Card.Processing and not data.to.dead then
        room:obtainCard(data.to, data.card, true, fk.ReasonJustMove, data.to, jianchu.name)
      end
    end
  end,
})

return jianchu
