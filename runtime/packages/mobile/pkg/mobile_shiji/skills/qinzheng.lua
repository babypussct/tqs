local qinzheng = fk.CreateSkill {
  name = "qinzheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qinzheng"] = "勤政",
  [":qinzheng"] = "锁定技，你每使用或打出：三张牌时，你随机获得一张【杀】或【闪】；五张牌时，你随机获得一张【桃】或【酒】；"..
  "八张牌时，你随机获得一张【无中生有】或【决斗】。",

  ["@qinzheng"] = "勤政",

  ["$qinzheng1"] = "夫国之有民，犹水之有舟，停则以安，扰则以危。",
  ["$qinzheng2"] = "治疾及其未笃，除患贵其莫深。",
}

qinzheng:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@" .. qinzheng.name, 0)
end)

local qinzheng_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinzheng.name) and
      not table.every({ 3, 5, 8 }, function(num)
        return player:getMark("@" .. qinzheng.name) % num ~= 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local loopList = table.filter({ 3, 5, 8 }, function(num)
      return player:getMark("@" .. qinzheng.name) % num == 0
    end)

    local cards = {}
    for _, count in ipairs(loopList) do
      local cardList = "slash,jink"
      if count == 5 then
        cardList = "peach,analeptic"
      elseif count == 8 then
        cardList = "ex_nihilo,duel"
      end
      local randomCard = player.room:getCardsFromPileByRule(cardList)
      if #randomCard > 0 then
        table.insert(cards, randomCard[1])
      end
    end

    if #cards > 0 then
      player.room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, qinzheng.name, nil, false, player)
    end
  end,
}
qinzheng:addEffect(fk.CardUsing, qinzheng_spec)
qinzheng:addEffect(fk.CardResponding, qinzheng_spec)

local qinzheng_refresh_spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinzheng.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@" .. qinzheng.name, 1)
  end,
}
qinzheng:addEffect(fk.CardUsing, qinzheng_refresh_spec)
qinzheng:addEffect(fk.CardResponding, qinzheng_refresh_spec)

return qinzheng
