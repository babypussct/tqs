local yangwu = fk.CreateSkill {
  name = "yangwu",
}

Fk:loadTranslationTable{
  ["yangwu"] = "扬武",
  [":yangwu"] = "出牌阶段限一次，你可以将一张<font color='red'>♥</font>手牌当【李代桃僵】使用；你使用的【李代桃僵】效果改为"..
  "观看目标角色的手牌并分配双方的手牌。",

  ["#yangwu"] = "扬武：将一张<font color='red'>♥</font>手牌当【李代桃僵】使用",
}

yangwu:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#yangwu",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart and
      table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("substituting")
    c.skillName = yangwu.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(yangwu.name, Player.HistoryPhase) == 0
  end,
})

yangwu:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(yangwu.name) and data.from == player and data.card.name == "substituting"
  end,
  on_refresh = function(self, event, target, player, data)
    data:changeCardSkill("yangwu__substituting_skill")
  end,
})

return yangwu
