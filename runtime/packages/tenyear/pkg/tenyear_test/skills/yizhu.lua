
local yizhu = fk.CreateSkill{
  name = "ty__yizhu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty__yizhu"] = "遗珠",
  [":ty__yizhu"] = "限定技，出牌阶段若你没有“明珠”，或你处于濒死状态时，你可以将所有红色牌交给一名其他角色。"..
  "若如此做，你回复等量体力并摸两张牌，然后〖怀姝〗的结束阶段改为每个结束阶段。",

  ["#ty__yizhu"] = "遗珠：将所有红色牌交给一名其他角色，你回复等量体力并摸两张牌",

  ["$ty__yizhu1"] = "",
  ["$ty__yizhu2"] = "",
}

yizhu:addEffect("active", {
  anim_type = "defensive",
  prompt = "#ty__yizhu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yizhu.name, Player.HistoryGame) == 0 and
      not table.find(player:getCardIds("h"), function (id)
        return table.contains(player:getTableMark("huaishu"), id)
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).color == Card.Red
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, yizhu.name, nil, false, player)
      if not player.dead then
        room:recover{
          who = player,
          num = #cards,
          skillName = yizhu.name,
          recoverBy = player,
        }
      end
    end
    if not player.dead then
      player:drawCards(2, yizhu.name)
    end
    if player:hasSkill("huaishu", true) then
      room:setPlayerMark(player, yizhu.name, 1)
    end
  end,
})

yizhu:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizhu.name) and player.dying and
      player:usedSkillTimes(yizhu.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = yizhu.name,
      prompt = "#ty__yizhu",
      cancelable = true,
      skip = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local skill = Fk.skills[yizhu.name]
    skill:onUse(player.room, {
      from = player,
      tos = event:getCostData(self).tos,
    })
  end,
})

return yizhu
