local zhoufu = fk.CreateSkill{
  name = "ol__zhoufu",
}

Fk:loadTranslationTable{
  ["ol__zhoufu"] = "咒缚",
  [":ol__zhoufu"] = "出牌阶段限一次，你可以将一张牌置于一名武将牌旁没有“咒”的其他角色的武将牌旁，称为“咒”；当有“咒”的角色判定时，"..
  "将“咒”作为判定牌；一名角色的回合结束时，你令本回合移除过“咒”的角色各失去1点体力。",

  ["#ol__zhoufu"] = "咒缚：将一张牌置为一名角色的“咒”",
  ["ol__zhangbao_zhou"] = "咒",

  ["$ol__zhoufu1"] = "走兽飞禽，术缚齐备。",
  ["$ol__zhoufu2"] = "符咒晚天成，术缚随人意！",
}

zhoufu:addEffect("active", {
  anim_type = "control",
  prompt = "#ol__zhoufu",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhoufu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player and #to_select:getPile("ol__zhangbao_zhou") == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    target:addToPile("ol__zhangbao_zhou", effect.cards, true, zhoufu.name, effect.from)
  end,
})

zhoufu:addEffect(fk.StartJudge, {
  can_refresh = function(self, event, target, player, data)
    return data.card == nil and target == player and #player:getPile("ol__zhangbao_zhou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.card = Fk:getCardById(player:getPile("ol__zhangbao_zhou")[1], true)
    --data.card.skillName = zhoufu.name
  end,
})

zhoufu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    if not player.dead then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName and info.fromSpecialName == "ol__zhangbao_zhou" then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, zhoufu.name, 1)
  end,
})

zhoufu:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhoufu.name) and
      table.find(player.room.alive_players, function (p)
        return p:getMark(zhoufu.name) > 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = table.filter(room.alive_players, function (p)
      return p:getMark(zhoufu.name) > 0
    end)
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        room:loseHp(p, 1, zhoufu.name)
      end
    end
  end,

  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return player:getMark(zhoufu.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, zhoufu.name, 0)
  end,
})

return zhoufu
