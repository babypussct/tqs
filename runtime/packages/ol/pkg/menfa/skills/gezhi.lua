local gezhi = fk.CreateSkill {
  name = "gezhi",
}

Fk:loadTranslationTable{
  ["gezhi"] = "革制",
  [":gezhi"] = "每回合限一次，当你或你攻击范围内的角色受到伤害后，若伤害来源不为你，你可弃置你和伤害来源各一张牌，且可分配这些牌。"..
  "若因此弃置牌的类别不同，你与伤害来源本回合只能使用这些类别的牌。",

  ["#gezhi-invoke"] = "革制：你可以弃置你和 %dest 各一张牌并分配",
  ["#gezhi-give"] = "革制：你可以分配这些牌",
  ["@gezhi-turn"] = "革制",

  ["$gezhi1"] = "天下十分君有其九，群生皆盼，此天人之应。",
  ["$gezhi2"] = "夏不以谦辞，周不吝诛放，畏知天命，无所与让。",
}

gezhi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gezhi.name) and player:usedSkillTimes(gezhi.name, Player.HistoryTurn) == 0 and
      (target == player or player:inMyAttackRange(target)) and data.from and data.from ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = gezhi.name,
      prompt = "#gezhi-invoke::"..data.from.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {data.from}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    local id1 = event:getCostData(self).cards[1]
    table.insert(types, Fk:getCardById(id1):getTypeString())
    room:throwCard(id1, gezhi.name, player, player)
    if player.dead or data.from.dead then return end
    local id2
    if not data.from.dead then
      id2 = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = gezhi.name,
      })
      table.insertIfNeed(types, Fk:getCardById(id2):getTypeString())
      room:throwCard(id2, gezhi.name, data.from, player)
    end
    if #types == 2 then
      if not player.dead then
        for _, t in ipairs(types) do
          room:addTableMarkIfNeed(player, "@gezhi-turn", t.."_char")
        end
      end
      if not data.from.dead then
        for _, t in ipairs(types) do
          room:addTableMarkIfNeed(data.from, "@gezhi-turn", t.."_char")
        end
      end
    end
    if player.dead then return end
    local cards = {}
    if table.contains(room.discard_pile, id1) then
      table.insert(cards, id1)
    end
    if table.contains(room.discard_pile, id2) then
      table.insertIfNeed(cards, id2)
    end
    if #cards > 0 then
      room:askToYiji(player, {
      targets = room.alive_players,
        cards = cards,
        skill_name = gezhi.name,
        min_num = 0,
        max_num = #cards,
        prompt = "#gezhi-give",
        expand_pile = cards,
      })
    end
  end,
})

gezhi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@gezhi-turn") ~= 0 and
      not table.contains(player:getTableMark("@gezhi-turn"), card:getTypeString() .. "_char")
  end,
})

return gezhi
