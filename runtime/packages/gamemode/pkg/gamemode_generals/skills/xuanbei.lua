local xuanbei = fk.CreateSkill {
  name = "nos__xuanbei",
}

Fk:loadTranslationTable{
  ["nos__xuanbei"] = "选备",
  [":nos__xuanbei"] = "游戏开始时，你获得两张带有应变效果的牌。每回合限一次，当你使用带有应变效果的牌结算后，你可以将之交给一名其他角色。",

  ["#nos__xuanbei-give"] = "选备：你可以将 %arg 交给一名其他角色",

  ["$nos__xuanbei1"] = "男胤有德色，愿陛下以备六宫。",
  ["$nos__xuanbei2"] = "广集良家，召充选者使吾拣择。",
}

xuanbei:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xuanbei.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.draw_pile, function(id)
      return table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark)
        return Fk:getCardById(id):getMark(mark) ~= 0
      end) ~= nil
    end)
    if #cards > 0 then
      room:moveCardTo(room:tableRandomPick(cards, 2), Card.PlayerHand, player, fk.ReasonJustMove, xuanbei.name, nil, false, player)
    end
  end,
})

xuanbei:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanbei.name) and not data.card:isVirtual() and
      table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark)
        return data.card:getMark(mark) ~= 0
      end) and
      player.room:getCardArea(data.card) == Card.Processing and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#nos__xuanbei-give:::" .. data.card:toLogString(),
      skill_name = xuanbei.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(data.card, Card.PlayerHand, to, fk.ReasonGive, xuanbei.name, nil, true, player)
  end,
})

return xuanbei
