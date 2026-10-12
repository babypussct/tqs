local zongshij = fk.CreateSkill{
  name = "m_ex__zongshij",
}

Fk:loadTranslationTable{
  ["m_ex__zongshij"] = "纵适",
  [":m_ex__zongshij"] = "当你拼点后，你观看牌堆顶的一张牌，并可以选择一项：获得牌堆顶的这张牌，或获得两张拼点牌中点数较小的一张。",

  ["#m_ex__zongshij-card"] = "纵适：选择一张获得",
  ["$PindianCard"] = "拼点牌",

  ["$m_ex__zongshij1"] = "空拘小节，难成大事。",
  ["$m_ex__zongshij2"] = "繁文缛节，不过是缚人之物。",
}

zongshij:addEffect(fk.PindianResultConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return (data.from == player or data.to == player) and player:hasSkill(zongshij.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top = room:getNCards(1)
    local card_data = { { "Top", top } }
    if data.winner == data.from then
      if room:getCardArea(data.toCard) == Card.Processing then
        table.insert(card_data, { "$PindianCard", {data.toCard:getEffectiveId()} })
      end
    elseif data.winner == data.to then
      if room:getCardArea(data.fromCard) == Card.Processing then
        table.insert(card_data, { "$PindianCard", {data.fromCard:getEffectiveId()} })
      end
    end
    local get = room:askToChooseCards(player, {
      target = player,
      flag = {
        card_data = card_data
      },
      skill_name = zongshij.name,
      prompt = "#m_ex__zongshij-card",
      min = 0,
      max = 1
    })
    if #get > 0 then
      room:obtainCard(player, get, get[1] ~= top[1], fk.ReasonPrey, player, zongshij.name)
    end
  end
})

return zongshij
