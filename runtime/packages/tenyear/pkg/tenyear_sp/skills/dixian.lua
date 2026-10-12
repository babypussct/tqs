
local dixian = fk.CreateSkill {
  name = "dixian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["dixian"] = "砥贤",
  [":dixian"] = "限定技，出牌阶段，你可以选择一个点数。若牌堆中所有牌均不小于此点数，你摸此点数张牌，你本局游戏使用不大于此点数的牌无距离次数限制；"..
  "若牌堆中有小于此点数的牌，你获得场上、牌堆和弃牌堆中所有点数为K的牌。",

  ["#dixian"] = "砥贤：选择一个点数，根据是否为牌堆最大点数执行效果",
  ["#dixian-choice"] = "砥贤：选择一个点数，根据是否为牌堆最大点数执行效果（牌堆最小为%arg点）",
  ["@dixian"] = "砥贤",

  ["$dixian1"] = "",
  ["$dixian2"] = "",
}

dixian:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#dixian",
  target_num = 0,
  card_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function (self, player)
    return player:usedSkillTimes(dixian.name, Player.HistoryGame) == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local min = 100
    for _, id in ipairs(room.draw_pile) do
      min = math.min(min, Fk:getCardById(id).number)
    end
    local n = room:askToNumber(player, {
      skill_name = dixian.name,
      prompt = "#dixian-choice:::"..min,
      min = 1,
      max = 13,
    })
    ---@cast n integer
    if min >= n then
      room:setPlayerMark(player, "@dixian", n)
      player:drawCards(n, dixian.name)
    else
      local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
        return Fk:getCardById(id).number == 13
      end)
      for _, p in ipairs(room:getAlivePlayers()) do
        for _, id in ipairs(p:getCardIds("ej")) do
          if Fk:getCardById(id).number == 13 then
            table.insert(cards, id)
          end
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, dixian.name, nil, false, player)
    end
  end,
})

dixian:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.number > 0 and
      data.card.number <= player:getMark("@dixian")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

dixian:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and player:getMark("@dixian") > 0 and card:matchVSPattern(".|1~"..player:getMark("@dixian"))
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and player:getMark("@dixian") > 0 and card:matchVSPattern(".|1~"..player:getMark("@dixian"))
  end,
})

return dixian
