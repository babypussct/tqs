local ganlu = fk.CreateSkill {
  name = "m_ex__ganlu",
}

Fk:loadTranslationTable{
  ["m_ex__ganlu"] = "甘露",
  [":m_ex__ganlu"] = "出牌阶段限一次，你可以选择两名装备区里的牌数之差不大于你已损失的体力值的角色，交换他们装备区里的牌；"..
    "若你选择的角色中含有你，则不受牌数之差的限制。",

  ["#m_ex__ganlu-active"] = "甘露：令两名装备区里的牌数之差不大于%arg的角色交换装备区里的牌，若选择自己则此无限制",

  ["$m_ex__ganlu1"] = "玄德实乃佳婿呀。",
  ["$m_ex__ganlu2"] = "好一个郎才女貌，真是天作之合啊。",
}

ganlu:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#m_ex__ganlu-active:::" .. tostring(player:getLostHp())
  end,
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return (selected[1] == player or to_select == player or
        math.abs(#to_select:getCardIds("e") - #selected[1]:getCardIds("e")) <= player:getLostHp()) and
        not (#to_select:getCardIds("e") == 0 and #selected[1]:getCardIds("e") == 0)
    end
  end,
  on_use = function(self, room, effect)
    room:swapAllCards(effect.from, effect.tos, ganlu.name, "e")
  end,
})

return ganlu
