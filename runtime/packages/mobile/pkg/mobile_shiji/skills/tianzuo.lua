local tianzuo = fk.CreateSkill {
  name = "tianzuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianzuo"] = "天佐",
  [":tianzuo"] = "锁定技，游戏开始时，将8张<a href=':raid_and_frontal_attack'>【奇正相生】</a>加入牌堆；【奇正相生】对你无效。",

  ["$tianzuo1"] = "此时进之多弊，守之多利，愿主公熟虑。",
  ["$tianzuo2"] = "主公若不时定，待四方生心，则无及矣。",
}

tianzuo:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianzuo.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = "raid_and_frontal_attack"
    local cards = {
      {name, Card.Spade, 2},
      {name, Card.Spade, 4},
      {name, Card.Spade, 6},
      {name, Card.Spade, 8},
      {name, Card.Club, 3},
      {name, Card.Club, 5},
      {name, Card.Club, 7},
      {name, Card.Club, 9},
    }
    room:changeCardArea(room:prepareDeriveCards(cards, tianzuo.name), Card.DrawPile)
  end,
})
tianzuo:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianzuo.name) and data.to == player and data.card.name == "raid_and_frontal_attack"
  end,
  on_use = function (self, event, target, player, data)
    data.nullified = true
  end,
})

return tianzuo
