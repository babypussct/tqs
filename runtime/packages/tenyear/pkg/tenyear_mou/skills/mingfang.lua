local mingfang = fk.CreateSkill {
  name = "mingfang",
}

Fk:loadTranslationTable{
  ["mingfang"] = "明访",
  [":mingfang"] = "回合开始时，你可以令一名其他角色展示一张手牌，此牌在其手牌中时，其受到的伤害+1。"..
  "出牌阶段开始时，你可以与一名其他角色拼点，若你赢，你对其造成1点伤害，本回合结束阶段可以再次拼点；若你没赢，你摸一张牌并与其横置。",

  ["#mingfang-show"] = "明访：令一名角色展示一张手牌，此牌在其手中时其受到伤害+1",
  ["#mingfang-ask"] = "明访：展示一张手牌，此牌在你手中时你受到伤害+1",
  ["@@mingfang-inhand"] = "明访",
  ["#mingfang-choose"] = "明访：与一名其他角色拼点，若赢则对其造成1点伤害",

  ["$mingfang1"] = "丞相勿忧，待我说得周瑜来降。",
  ["$mingfang2"] = "公瑾，有朋来谒，何不远迎？",
}

mingfang:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(mingfang.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#mingfang-show",
      skill_name = mingfang.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      skill_name = mingfang.name,
      prompt = "#mingfang-ask",
      cancelable = false,
    })
    to:showCards(cards)
    if table.contains(to:getCardIds("h"), cards[1]) then
      room:setCardMark(Fk:getCardById(cards[1]), "@@mingfang-inhand", 1)
    end
  end,
})

mingfang:addEffect(fk.DamageInflicted, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@mingfang-inhand") > 0
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    local n = #table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@mingfang-inhand") > 0
    end)
    data:changeDamage(n)
  end,
})

mingfang:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingfang.name) and
      (player.phase == Player.Finish and player:getMark("mingfang-turn") > 0 or player.phase == Player.Play) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#mingfang-choose",
      skill_name = mingfang.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({ to }, mingfang.name)
    if pindian.results[to].winner == player then
      if not player.dead then
        room:setPlayerMark(player, "mingfang-turn", 1)
      end
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = mingfang.name,
        }
      end
    else
      if player:isAlive() then
        player:drawCards(1, mingfang.name)
      end

      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not to.dead and not to.chained then
        to:setChainState(true)
      end
    end
  end,
})

return mingfang
