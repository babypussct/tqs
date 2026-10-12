local mingfa = fk.CreateSkill {
  name = "mingfa",
  derived_piles = "mingfa",
}

Fk:loadTranslationTable{
  ["mingfa"] = "明伐",
  [":mingfa"] = "每阶段限一次，当你于出牌阶段使用非转化的【杀】或普通锦囊牌结算完毕后，若你没有“明伐”牌，你可以将此牌置于武将牌上并"..
  "选择一名其他角色。该角色的结束阶段，视为你对其使用X张“明伐”牌（X为其手牌数，最少为1，最多为5），然后移去“明伐”牌。",

  ["#mingfa-choose"] = "明伐：将%arg置为“明伐”，选择一名角色，其结束阶段视为对其使用“明伐”牌！",
  ["@@mingfa"] = "明伐",
  ["#mingfa-choose2"] = "明伐：选择对 %dest 使用【%arg】的副目标",

  ["$mingfa1"] = "煌煌大势，无须诈取。",
  ["$mingfa2"] = "开示公道，不为掩袭。",
}

mingfa:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingfa.name) and player.phase == Player.Play and
      #player:getPile(mingfa.name) == 0 and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      not data.card.is_passive and not data.card:isVirtual() and
      player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(mingfa.name, Player.HistoryPhase) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#mingfa-choose:::"..data.card:toLogString(),
      skill_name = mingfa.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@mingfa", player.id)
    player:addToPile(mingfa.name, data.card, true, mingfa.name)
  end,
})

mingfa:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return not target.dead and target.phase == Player.Finish and
      player:hasSkill(mingfa.name) and table.contains(target:getTableMark("@@mingfa"), player.id)
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, {tos = { target }})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(target, "@@mingfa", player.id)
    local cards = player:getPile(mingfa.name)
    if #cards == 0 then return end
    local card = Fk:getCardById(cards[1])
    --实测桃酒会对自己使用，甚至能使用虚拟的延时锦囊，这里还是直接排除吧……
    if card.trueName == "slash" or card:isCommonTrick() then
      local card_name = card.name
      local x = math.min(math.max(target:getHandcardNum(), 1), 5)
      local extra_data = { bypass_distances = true, bypass_times = true }
      for _ = 1, x, 1 do
        if player.dead or target.dead then break end
        card = Fk:cloneCard(card_name)
        card.skillName = mingfa.name
        if not player:canUseTo(card, target, extra_data) then
          break
        end
        local tos = { target }
        local n = card.skill:getMinTargetNum(player)
        if n == 2 then
          local sub_tos = table.filter(room.alive_players, function (p)
            return card.skill:targetFilter(player, p, tos, {}, card, extra_data)
          end)
          if #sub_tos > 0 then
            local sub_to = room:askToChoosePlayers(player, {
              min_num = 1,
              max_num = 1,
              targets = sub_tos,
              skill_name = mingfa.name,
              prompt = "#mingfa-choose2::" .. target.id .. ":" .. card_name,
              cancelable = false,
            })
            table.insert(tos, sub_to[1])
          else
            break
          end
        end
        room:useCard{
          card = card,
          from = player,
          tos = tos,
          extraUse = true,
        }
      end
    end
    cards = player:getPile(mingfa.name)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, mingfa.name, nil, true, player)
    end
  end
})

mingfa:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@@mingfa")
    room:setPlayerMark(player, "@@mingfa", 0)
    local cards = {}
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@mingfa", player.id)
      if table.contains(mark, p.id) then
        table.insertTable(cards, p:getPile(mingfa.name))
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, mingfa.name, nil, true)
    end
  end
})

mingfa:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@mingfa", player.id)
  end
end)

return mingfa
