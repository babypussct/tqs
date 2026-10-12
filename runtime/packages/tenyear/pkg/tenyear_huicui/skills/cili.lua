
local cili = fk.CreateSkill{
  name = "cili",
}

Fk:loadTranslationTable{
  ["cili"] = "慈厉",
  [":cili"] = "每轮开始时，你可以选择一名角色并记录其当前体力值，直到其下个回合结束，若其使用的牌数："..
  "小于记录值，你可以令其随机弃置记录值张牌；大于等于记录值，你可以其摸记录值张牌（至多五张）。",

  ["@cili-round"] = "慈厉",
  ["#cili-choose"] = "慈厉：选择一名角色，记录其体力值，其回合结束时根据使用牌数执行效果",
  ["#cili-discard"] = "慈厉：你可以令%dest弃置%arg张牌",
  ["#cili-draw"] = "慈厉：你可以令%dest摸%arg张牌",

  ["$cili1"] = "廊外风霜重，回堂在添衣。",
  ["$cili2"] = "温良恭俭让，勿忘之本心。",
}

cili:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cili.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#cili-choose",
      skill_name = cili.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@cili-round", "0/"..to.hp)
    room:addTableMark(to, "cili-round", player)
  end,
})

cili:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(cili.name) and
      table.contains(target:getTableMark("cili-round"), player)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local mark = string.split(target:getMark("@cili-round"), "/")
    local n1, n2 = tonumber(mark[1]), tonumber(mark[2])
    if n2 > n1 then
      if not target:isNude() and
        room:askToSkillInvoke(player, {
          skill_name = cili.name,
          prompt = "#cili-discard::"..target.id..":"..n2,
        }) then
        event:setCostData(self, { tos = { target }, choice = "discard", n = n2 })
        return true
      end
    elseif not target.dead then
      if room:askToSkillInvoke(player, {
          skill_name = cili.name,
          prompt = "#cili-draw::"..target.id..":"..n2,
        }) then
        event:setCostData(self, { tos = { target }, choice = "draw", n = n2 })
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local n = math.min(event:getCostData(self).n, 5)
    if choice == "discard" then
      room:throwCard(room:tableRandomPick(target:getCardIds("he"), n), cili.name, target, target)
    else
      target:drawCards(n, cili.name)
    end
  end,

  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@cili-round", 0)
    room:setPlayerMark(player, "cili-round", 0)
  end,
})

cili:addEffect(fk.CardUsing, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@cili-round") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = string.split(player:getMark("@cili-round"), "/")
    local n1, n2 = tonumber(mark[1]), mark[2]
    n1 = n1 + 1
    room:setPlayerMark(player, "@cili-round", n1.."/"..n2)
  end,
})

return cili
