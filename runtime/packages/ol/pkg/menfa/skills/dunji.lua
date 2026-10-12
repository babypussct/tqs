
local dunji = fk.CreateSkill{
  name = "dunji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dunji"] = "遁迹",
  [":dunji"] = "锁定技，当你每回合首次使用黑色牌后，你令一名角色用一张手牌交换此牌。",

  ["#dunji-choose"] = "遁迹：令一名角色用一张手牌交换此%arg",
  ["#dunji-ask"] = "遁迹：请用一张手牌交换此%arg",
  ["@[chara]dunji"] = "遁迹",

  ["$dunji1"] = "",
  ["$dunji2"] = "",
}

dunji:addEffect(fk.CardUseFinished, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(dunji.name) and data.card.color == Card.Black and
      player:usedSkillTimes(dunji.name, Player.HistoryTurn) == 0 and
      table.contains({ Card.Processing }, player.room:getCardArea(data.card)) and --？
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end) then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player and e.data.card.color == Card.Black
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = dunji.name,
      prompt = "#dunji-choose:::"..data.card:toLogString(),
      cancelable = false,
    })[1]
    room:setPlayerMark(player, "@[chara]dunji", to.id)
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = dunji.name,
      prompt = "#dunji-ask:::"..data.card:toLogString(),
      cancelable = false,
    })
    local moves = {}
    table.insert(moves, {
      ids = card,
      from = to,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonExchange,
      skillName = dunji.name,
      proposer = to,
    })
    table.insert(moves, {
      ids = Card:getIdList(data.card),
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      skillName = dunji.name,
      proposer = to,
    })
    room:moveCards(table.unpack(moves))
  end,
})

return dunji
