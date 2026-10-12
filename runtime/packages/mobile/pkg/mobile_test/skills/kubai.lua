local kubai = fk.CreateSkill {
  name = "kubai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kubai"] = "枯白",
  [":kubai"] = "1级：锁定技，你于回合内使用每种颜色的第一张牌时，你摸一张牌；其他角色于你的回合内不能使用有颜色且你未使用过的颜色的牌。<br/>" ..
  "2级：锁定技，你于回合内使用每种花色的第一张牌时，你摸一张牌；其他角色于你的回合内不能使用有花色且你未使用过的花色的牌。<br/>" ..
  "3级：锁定技，你于回合内使用每种点数的第一张牌时，你摸一张牌；其他角色于你的回合内不能使用有点数且你未使用过的点数的牌。",

  ["@kubai_level"] = "枯白等级",

  ["$kubai1"] = "字之体势，须一笔而成。",
  ["$kubai2"] = "偶有不连，而血脉不断。",
  ["$kubai3"] = "专精一体，方致绝伦。",
  ["$kubai4"] = "五合交臻，神融笔畅。",
  ["$kubai5"] = "转精其巧，亦可后来居上。",
  ["$kubai6"] = "一笔飞白，可堪独步无双。",
}

kubai:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kubai.name) and player.room:getCurrent() == player then
      if player:getMark("@kubai_level") <= 1 then
        return (data.extra_data or {}).kubai_color
      elseif player:getMark("@kubai_level") == 2 then
        return (data.extra_data or {}).kubai_suit
      else
        return (data.extra_data or {}).kubai_number
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, kubai.name)
  end,
})

kubai:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(kubai.name, true) and player.room:getCurrent() == player then
      if player:getMark("@kubai_level") <= 1 then
        return data.card.color ~= Card.NoColor
      elseif player:getMark("@kubai_level") == 2 then
        return data.card.suit ~= Card.NoSuit
      else
        return data.card.number > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    if player:getMark("@kubai_level") <= 1 then
      if room:addTableMarkIfNeed(player, "kubai_color-turn", data.card:getColorString()) then
        data.extra_data.kubai_color = true
      end
    elseif player:getMark("@kubai_level") == 2 then
      if room:addTableMarkIfNeed(player, "kubai_suit-turn", data.card:getSuitString()) then
        data.extra_data.kubai_suit = true
      end
    else
      if room:addTableMarkIfNeed(player, "kubai_number-turn", data.card.number) then
        data.extra_data.kubai_number = true
      end
    end
  end,
})

kubai:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local current = Fk:currentRoom():getCurrent()
    if card and current and current:hasSkill(kubai.name) and current ~= player then
      if current:getMark("@kubai_level") <= 1 then
        return card.color ~= Card.NoColor and
          not table.contains(current:getTableMark("kubai_color-turn"), card:getColorString())
      elseif current:getMark("@kubai_level") == 2 then
        return card.suit ~= Card.NoSuit and
          not table.contains(current:getTableMark("kubai_suit-turn"), card:getSuitString())
      else
        return card.number > 0 and
          not table.contains(current:getTableMark("kubai_number-turn"), card.number)
      end
    end
  end,
})

kubai:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@kubai_level", 1)
end)

kubai:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@kubai_level", 0)
  end
end)

return kubai
