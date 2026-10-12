local yingshi = fk.CreateSkill{
  name = "yingshis",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yingshis"] = "鹰视",
  [":yingshis"] = "锁定技，出牌阶段，牌堆顶X张牌始终对你可见（X为你的体力上限）。",

  ["@[yingshis]"] = "鹰视",

  ["$yingshis1"] = "鹰扬千里，明察秋毫。",
  ["$yingshis2"] = "鸢飞戾天，目入百川。",
}

yingshi:addEffect("targetmod", {
})

Fk:addQmlMark{
  name = "yingshis",
  how_to_show = function(name, value, p)
    if Self:isBuddy(p) and p.phase == Player.Play and p:hasSkill(yingshi.name) then
      return " "
    end
    return "#hidden"
  end,
  qml = function(name, value, p)
    if Self:isBuddy(p) and p.phase == Player.Play and p:hasSkill(yingshi.name) then
      local drawPile = Fk:currentRoom().draw_pile
      local cards = {}
      for i = 1, math.min(p.maxHp, #drawPile), 1 do
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

yingshi:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "@[yingshis]", 1)
end)

yingshi:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@[yingshis]", 0)
end)

return yingshi
