local skill = fk.CreateSkill {
  name = "enemy_at_the_gates_skill",
}

Fk:loadTranslationTable{
  ["enemy_at_the_gates_skill"] = "兵临城下",
  [":enemy_at_the_gates_skill"] = "选择一名其他角色，你依次亮出牌堆顶四张牌，若为【杀】你对其使用之，若不为【杀】则置入弃牌堆",
}

skill:addEffect("cardskill", {
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    local cards = {}
    local total = 4
    if effect.extra_data and effect.extra_data.num then
      total = total + effect.extra_data.num
      if total < 1 then return end
    end
    for _ = 1, total do
      local id = room:getNCards(1)[1]
      table.insert(cards, id)
      room:turnOverCardsFromDrawPile(player, {id}, skill.name, true)
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
        room:useCard({
          card = card,
          from = player,
          tos = {to},
          extraUse = true,
          extra_data = { useByEnemyAtGate = true },
        })
      end
    end
    room:cleanProcessingArea(cards, skill.name)
  end,
})

return skill
