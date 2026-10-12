local zhenyi = fk.CreateSkill {
  name = "zhenyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "锁定技，当“法箓”移除三个同花色后，你本局游戏使用此花色的牌无距离限制且不能被响应。"..
  "当“法箓”移除三个各不相同的花色后，你本局游戏“点化”可观看的牌数+1（最多+4）。",

  ["@zhenyi"] = "真仪",

  ["$zhenyi1"] = "不疾不徐，自爱自重。",
  ["$zhenyi2"] = "紫薇星辰，斗数之仪。",
}

zhenyi:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("@zhenyi"), data.card:getSuitString(true))
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

zhenyi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    local mark = player:getTableMark("@zhenyi")
    if #mark > 0 then
      return card and card:matchVSPattern(".|.|" ..
        table.concat(table.map(mark, function(suit) return string.sub(suit, 5) end), ","))
    end
  end,
})

zhenyi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@zhenyi", 0)
end)

return zhenyi
