
local zhuiyiw = fk.CreateSkill {
  name = "zhuiyiw",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhuiyiw"] = "追懿",
  [":zhuiyiw"] = "锁定技，你使用牌结算完毕后，若你是本局游戏使用此牌名的牌数唯一最多的，你摸一张牌；"..
  "你死亡时，令一名其他角色从牌堆获得触发过此技能的牌名不同的牌各一张。",

  ["@$zhuiyiw"] = "追懿",
  ["#zhuiyiw-choose"] = "追懿：令一名其他角色获得每种“追懿”牌各一张",

  ["$zhuiyiw1"] = "",
  ["$zhuiyiw2"] = "",
}

zhuiyiw:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhuiyiw.name) and
      data.from == player and data.extra_data and data.extra_data.zhuiyiw
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@$zhuiyiw", data.card.trueName)
    player:drawCards(1, zhuiyiw.name)
  end,

  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhuiyiw.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark(zhuiyiw.name)
    mark[data.card.trueName] = mark[data.card.trueName] or {}
    mark[data.card.trueName][data.from] = (mark[data.card.trueName][data.from] or 0) + 1
    if data.from == player then
      local yes = true
      for p, n in pairs(mark[data.card.trueName]) do
        if p ~= player and n >= mark[data.card.trueName][player] then
          yes = false
          break
        end
      end
      if yes then
        data.extra_data = data.extra_data or {}
        data.extra_data.zhuiyiw = true
      end
    end
    room:setPlayerMark(player, zhuiyiw.name, mark)
  end,
})

zhuiyiw:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiyiw.name, false, true) and
      #player.room:getOtherPlayers(player, false) > 0 and player:getMark("@$zhuiyiw") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = zhuiyiw.name,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#zhuiyiw-choose",
      cancelable = false,
    })[1]
    local names = player:getTableMark("@$zhuiyiw")
    local cards = {}
    for i = #room.draw_pile, 1, -1 do
      if table.removeOne(names, Fk:getCardById(room.draw_pile[i]).trueName) then
        table.insert(cards, room.draw_pile[i])
      end
    end
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, zhuiyiw.name, nil, false, player)
  end,
})

return zhuiyiw
