local zhitian = fk.CreateSkill{
  name = "zhitian",
}

Fk:loadTranslationTable{
  ["zhitian"] = "知天",
  [":zhitian"] = "出牌阶段，牌堆顶的7张牌对你可见。你的【火攻】结算中，你可观看并选择牌堆顶7张牌中的一张牌代替【火攻】弃牌。",

  ["@[zhitian]"] = "知天",

  ["$zhitian1"] = "天火熊熊，再兴炎汉国祚！",
  ["$zhitian2"] = "地火愔愔，燎尽不臣之贼！",
}

Fk:addQmlMark{
  name = "zhitian",
  how_to_show = function(name, value, p)
    return tostring(value)
  end,
  qml = function(name, value, p)
    if Self:isBuddy(p) and p.phase == Player.Play and p:hasSkill(zhitian.name) then
      if type(value) ~= "number" or value < 1 then return {} end
      local drawPile = Fk:currentRoom().draw_pile
      local cards = {}
      for i = 1, math.min(value, #drawPile), 1 do
        table.insert(cards, drawPile[i])
      end
      return {
        uri = "LunarLtk.Pages.InfoPopups",
        name = "ViewPile",
        prop = {
          ids = cards
        },
      }
    end
    return {}
  end,
}

zhitian:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zhitian.name) and data.from == player and data.card.trueName == "fire_attack"
  end,
  on_refresh = function(self, event, target, player, data)
    data:changeCardSkill("zhitian__fire_attack_skill")
  end,
})

zhitian:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "@[zhitian]", 7)
end)

zhitian:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@[zhitian]", 0)
end)

return zhitian
