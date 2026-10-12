local zhoufu = fk.CreateSkill{
  name = "mobile__zhoufu",
}

Fk:loadTranslationTable{
  ["mobile__zhoufu"] = "咒缚",
  [":mobile__zhoufu"] = "出牌阶段限一次，你可以将一张手牌置于一名没有“咒”的其他角色的武将牌旁，称为“咒”；"..
  "当有“咒”的角色判定时，将“咒”作为判定牌；一名角色的回合结束时，你令本回合移除过“咒”的角色各失去1点体力。",

  ["#mobile__zhoufu"] = "咒缚：将一张牌置为一名角色的“咒”",
  ["mobile__zhangbao_zhou"] = "咒",

  ["$mobile__zhoufu1"] = "违吾咒者，倾死灭亡！",
  ["$mobile__zhoufu2"] = "咒宝符命，速显威灵！",
}

zhoufu:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__zhoufu",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhoufu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player and #to_select:getPile("mobile__zhangbao_zhou") == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    target:addToPile("mobile__zhangbao_zhou", effect.cards, true, zhoufu.name, effect.from)
  end,
})

zhoufu:addEffect(fk.StartJudge, {
  can_refresh = function(self, event, target, player, data)
    return target == player and #player:getPile("mobile__zhangbao_zhou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.card = Fk:getCardById(player:getPile("mobile__zhangbao_zhou")[1])
    data.card.skillName = zhoufu.name
  end,
})

zhoufu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    if not player.dead then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName and info.fromSpecialName == "mobile__zhangbao_zhou" then
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
