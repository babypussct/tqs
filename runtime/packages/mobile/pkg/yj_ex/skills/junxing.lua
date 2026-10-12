local junxing = fk.CreateSkill {
  name = "m_ex__junxing",
}

Fk:loadTranslationTable{
  ["m_ex__junxing"] = "峻刑",
  [":m_ex__junxing"] = "出牌阶段限一次，你可以弃置任意张手牌并令一名其他角色选择一项：1.弃置等量的牌并失去1点体力；2.翻面，然后摸等量的牌。",

  ["#m_ex__junxing-active"] = "发动峻刑，选择任意张手牌弃置并选择一名其他角色",
  ["#m_ex__junxing-discard"] = "峻刑：选择弃置%arg张牌并失去1点体力，或点取消则翻面并摸%arg张牌",

  ["$m_ex__junxing1"] = "严法尚公，岂分贵贱而异施？",
  ["$m_ex__junxing2"] = "情理可容之事，法未必能容！",
}

junxing:addEffect("active", {
  anim_type = "control",
  prompt = "#m_ex__junxing-active",
  max_phase_use_time = 1,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and #selected_cards > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local x = #effect.cards
    room:throwCard(effect.cards, junxing.name, player)
    if target.dead then return end
    if #room:askToDiscard(target, {
      min_num = x,
      max_num = x,
      include_equip = true,
      skill_name = junxing.name,
      cancelable = true,
      pattern = ".",
      prompt = "#m_ex__junxing-discard:::"..x
    }) == 0 then
      target:turnOver()
      if target.dead then return end
      room:drawCards(target, x, junxing.name)
    else
      if target.dead then return end
      room:loseHp(target, 1, junxing.name)
    end
  end,
})

return junxing
