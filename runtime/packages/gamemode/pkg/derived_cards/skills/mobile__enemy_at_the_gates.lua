local skill = fk.CreateSkill {
  name = "mobile__enemy_at_the_gates_skill",
}

Fk:loadTranslationTable{
  ["mobile__enemy_at_the_gates_skill"] = "兵临城下",
  ["#mobile__enemy_at_the_gates_skill"] = "选择一名其他角色，你展示牌堆顶四张牌，依次对其使用其中【杀】，其余放回牌堆顶",
}

skill:addEffect("cardskill", {
  prompt = "#mobile__enemy_at_the_gates_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local to = effect.to
    local cards = room:getNCards(4)
    room:turnOverCardsFromDrawPile(player, cards, skill.name)
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and not player:prohibitUse(card) and not player:isProhibited(to, card) and to:isAlive() then
        room:useCard({
          card = card,
          from = player,
          tos = { to },
          extraUse = true,
          extra_data = { useByEnemyAtGate = true },
        })
      end
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:delay(#cards * 150)
      room:moveCardTo(table.reverse(cards), Card.DrawPile, nil, fk.ReasonPut, skill.name, nil, true, player)
    end
  end,
})

return skill
