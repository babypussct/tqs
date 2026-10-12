local jiantong = fk.CreateSkill{
  name = "heg__jiantong",
}

Fk:loadTranslationTable{
  ["heg__jiantong"] = "监统",
  [":heg__jiantong"] = "当你受到伤害后，你可以观看一名角色的手牌，然后你可以用装备区内的一张牌交换其中至多两张牌。",

  ["#heg__jiantong-choose"] = "监统：观看一名角色的手牌，你可以用一张装备交换其中至多两张牌",
  ["#heg__jiantong-exchange"] = "监统：你可以用一张装备交换其中至多两张牌",

  ["$heg__jiantong1"] = "秉公行事，无所亲疏。",
  ["$heg__jiantong2"] = "明晰法理，通晓人情。",
}

Fk:addPoxiMethod{
  name = "heg__jiantong",
  prompt = "#heg__jiantong-exchange",
  card_filter = function(to_select, selected, data)
    local equips = data[2][2]
    if #equips == 0 then
      return false
    else
      if #selected == 0 then
        return true
      elseif #selected < 3 then
        if table.find(selected, function (id)
          return table.contains(equips, id)
        end) then
          return table.contains(data[1][2], to_select)
        else
          return #selected < 2 or table.contains(equips, to_select)
        end
      end
    end
  end,
  feasible = function (selected, data, extra_data)
    return #selected < 4 and #selected > 1 and
      #table.filter(selected, function (id)
        return table.contains(data[2][2], id)
      end) == 1
  end,
}

jiantong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiantong.name) and
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
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jiantong.name,
      prompt = "#heg__jiantong-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local result = room:askToPoxi(player, {
      poxi_type = jiantong.name,
      data = {
        { to.general, to:getCardIds("h") },
        { player.general, player:getCardIds("e") }
      },
      cancelable = true,
    })
    if #result > 0 then
      local cards1 = table.filter(result, function (id)
        return table.contains(player:getCardIds("e"), id)
      end)
      table.removeOne(result, cards1[1])
      local moves = {}
      table.insert(moves, {
        ids = cards1,
        from = player,
        to = to,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        skillName = jiantong.name,
        proposer = player,
        moveVisible = true,
      })
      table.insert(moves, {
        ids = result,
        from = to,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        skillName = jiantong.name,
        proposer = player,
        moveVisible = false,
      })
      room:moveCards(table.unpack(moves))
    end
  end,
})

jiantong:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return jiantong

