local xingtu = fk.CreateSkill{
  name = "xingtu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xingtu"] = "行图",
  [":xingtu"] = "锁定技，当你使用牌时，若此牌的点数为X的因数，你摸一张牌；你使用点数为X的倍数的牌无次数限制（X为你使用的上一张牌的点数）。",

  ["@xingtu"] = "行图",

  ["$xingtu1"] = "制图之体有六，缺一不可言精。",
  ["$xingtu2"] = "图设分率，则宇内地域皆可绘于一尺。",
}

xingtu:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingtu.name) and data.card.number > 0 and
      data.extra_data and data.extra_data.xingtu and
      data.extra_data.xingtu % data.card.number == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xingtu.name)
  end,
})
xingtu:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingtu.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local lastNumber = player:getMark("@xingtu")
    local realNumber = math.max(data.card.number, 0)
    player.room:setPlayerMark(player, "@xingtu", realNumber)
    if lastNumber > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.xingtu = lastNumber
    end
  end,
})
xingtu:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    if player:getMark("@xingtu") > 0 and player:hasSkill(self) and card then
      local numbers = {}
      for i = 1, 13, 1 do
        if i % player:getMark("@xingtu") == 0 then
          table.insert(numbers, tostring(i))
        end
      end
      return card:matchVSPattern(".|" .. table.concat(numbers, ","))
    end
  end,
})

xingtu:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        room:setPlayerMark(player, "@xingtu", use.card.number)
        return true
      end
    end, 0)
  end
end)
xingtu:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@xingtu", 0)
end)

return xingtu
