local shutong = fk.CreateSkill {
  name = "shutong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shutong"] = "束统",
  [":shutong"] = "锁定技，你使用一张牌指定目标后，本回合你与目标角色使用的下一张牌不能为此花色。若目标角色均与你体力值相同，你摸一张牌。",

  ["@shutong-turn"] = "束统",

  ["$shutong1"] = "宜循春秋之义，秉承正统。",
  ["$shutong2"] = "整束古仁人之礼，统饬今世。",
}

shutong:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shutong.name) and data.firstTarget
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.suit ~= Card.NoSuit then
      room:setPlayerMark(player, "@shutong-turn", data.card:getSuitString(true))
      for _, p in ipairs(data.use.tos) do
        room:setPlayerMark(p, "@shutong-turn", data.card:getSuitString(true))
      end
    end
    if table.every(data.use.tos, function (p)
      return p.hp == player.hp
    end) then
      player:drawCards(1, shutong.name)
    end
  end,
})

shutong:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@shutong-turn", 0)
  end,
})

shutong:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local suit = player:getMark("@shutong-turn")
    if suit == 0 then return end
    suit = string.sub(suit, 5)
    return not card:matchVSPattern(".|.|^"..suit)
  end,
})

return shutong
