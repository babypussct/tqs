local ganggeng = fk.CreateSkill {
  name = "ganggeng",
}

Fk:loadTranslationTable{
  ["ganggeng"] = "刚鲠",
  [":ganggeng"] = "出牌阶段限一次，你可以将至少两张手牌交给一名其他角色。回合结束时，若其手牌数：为全场最多，你摸一张牌；"..
  "不为全场最多，你弃置其区域里的一张牌。",

  ["#ganggeng"] = "刚鲠：将至少两张手牌交给一名角色，回合结束时根据其是否手牌最多执行效果",
  ["@@ganggeng-turn"] = "刚鲠",

  ["$ganggeng1"] = "犯颜敢谏，何惧一死乎？",
  ["$ganggeng2"] = "丰有良言，将军何不纳之？",
  ["$ganggeng3"] = "将军今得天时，此战必可胜之。",
  ["$ganggeng4"] = "唉，大势去矣，大势去矣！",
}

ganggeng:addEffect("active", {
  anim_type = "support",
  audio_index = {1, 2},
  prompt = "#ganggeng",
  min_card_num = 2,
  target_num = 1,
  can_use = function (self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(target, "@@ganggeng-turn", player)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, ganggeng.name, nil, false, player)
  end,
})

ganggeng:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(ganggeng.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@@ganggeng-turn") == player
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p:getMark("@@ganggeng-turn") == player then
        room:setPlayerMark(p, "@@ganggeng-turn", 0)
        if not player.dead then
          room:doIndicate(player, {p})
          if table.every(room.alive_players, function (q)
            return p:getHandcardNum() >= q:getHandcardNum()
          end) then
            player:broadcastSkillInvoke(ganggeng.name, 3)
            room:notifySkillInvoked(player, ganggeng.name, "drawcard")
            player:drawCards(1, ganggeng.name)
          else
            player:broadcastSkillInvoke(ganggeng.name, 4)
            room:notifySkillInvoked(player, ganggeng.name, "control")
            if not p:isAllNude() then
              local card = room:askToChooseCard(player, {
                target = p,
                flag = "hej",
                skill_name = ganggeng.name,
              })
              room:throwCard(card, ganggeng.name, p, player)
            end
          end
        end
      end
    end
  end,
})

return ganggeng
