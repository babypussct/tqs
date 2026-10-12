local kudu = fk.CreateSkill{
  name = "kudu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["kudu"] = "苦渡",
  [":kudu"] = "限定技，结束阶段，你可以重铸两张牌，令一名角色下X个回合结束时摸一张牌，其第X个回合后执行一个额外回合"..
  "（X为你重铸牌点数之差且至多为5）。",

  ["#kudu-choose"] = "苦渡：重铸两张牌，根据点数之差，令一名角色摸牌",
  ["@kudu"] = "苦渡",

  ["$kudu1"] = "大河汤汤，行路艰难辛苦。",
  ["$kudu2"] = "羁途苦旅，终见月明花开。",
}

kudu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(kudu.name) and player.phase == Player.Finish and
      player:usedSkillTimes(kudu.name, Player.HistoryGame) == 0 and
      #player:getCardIds("he") > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 2,
      max_card_num = 2,
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = kudu.name,
      prompt = "#kudu-choose",
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, {tos = to, cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    local n = math.abs(Fk:getCardById(cards[1]).number - Fk:getCardById(cards[2]).number)
    n = math.min(n, 5)
    room:recastCard(cards, player, kudu.name)
    if n == 0 or to.dead then return end
    room:addTableMark(to, kudu.name, n)
    n = math.max(table.unpack(to:getTableMark(kudu.name)))
    room:setPlayerMark(to, "@kudu", n)
  end
})

kudu:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark(kudu.name) ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n, extra_turn = 0, 0
    local mark = {}
    for _, i in ipairs(player:getTableMark(kudu.name)) do
      n = n + 1
      if i > 1 then
        table.insert(mark, i - 1)
      else
        extra_turn = extra_turn + 1
      end
    end
    room:setPlayerMark(player, kudu.name, #mark > 0 and mark or 0)
    if #mark > 0 then
      room:setPlayerMark(player, "@kudu", math.max(table.unpack(mark)))
    else
      room:setPlayerMark(player, "@kudu", 0)
    end
    player:drawCards(n, kudu.name)
    if not player.dead and extra_turn > 0 then
      for _ = 1, extra_turn do
        player:gainAnExtraTurn(true, kudu.name)
      end
    end
  end,
})

return kudu
