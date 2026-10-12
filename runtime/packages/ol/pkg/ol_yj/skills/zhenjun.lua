local zhenjun = fk.CreateSkill {
  name = "ol__zhenjun",
}

Fk:loadTranslationTable {
  ["ol__zhenjun"] = "镇军",
  [":ol__zhenjun"] = "准备阶段，你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1），然后你选择一项：" ..
      "1.弃置其中非装备牌张数的牌；2.该角色摸其中非装备牌张数的牌。",

  ["#ol__zhenjun-choose"] = "镇军：选择一名角色，弃置其手牌数减体力值张牌（至少一张）",
  ["#ol__zhenjun-card"] = "镇军：弃置 %dest %arg张牌，然后选择弃牌或令其摸牌",
  ["#ol__zhenjun-discard"] = "镇军：弃置%arg张牌，或点“取消” %dest 摸%arg张牌",

  ["$ol__zhenjun1"] = "治军，以武为纪！",
  ["$ol__zhenjun2"] = "严守纪法，不得有误！",
}

zhenjun:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenjun.name) and player.phase == Player.Start and
        table.find(player.room.alive_players, function(p)
          return not p:isNude()
        end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    if table.contains(targets, player) and
        not table.find(player:getCardIds("he"), function(id)
          return not player:prohibitDiscard(id)
        end) then
      table.removeOne(targets, player)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhenjun.name,
      prompt = "#ol__zhenjun-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local num = math.min(math.max(1, to:getHandcardNum() - to.hp), #to:getCardIds("he"))
    local cards
    if to == player then
      cards = room:askToDiscard(player, {
        min_num = num,
        max_num = num,
        include_equip = true,
        skill_name = zhenjun.name,
        cancelable = false,
        prompt = "#ol__zhenjun-card::" .. to.id .. ":" .. num,
        skip = true,
      })
    else
      cards = room:askToChooseCards(player, {
        target = to,
        min = num,
        max = num,
        flag = "he",
        skill_name = zhenjun.name,
        prompt = "#ol__zhenjun-card::" .. to.id .. ":" .. num
      })
    end
    num = #table.filter(cards, function(id)
      return Fk:getCardById(id).type ~= Card.TypeEquip
    end)
    room:throwCard(cards, zhenjun.name, to, player)
    if player.dead or num == 0 then return end
    if player:isNude() or
        #room:askToDiscard(player, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = zhenjun.name,
          prompt = "#ol__zhenjun-discard::" .. to.id .. ":" .. num,
        }) == 0 then
      to:drawCards(num, zhenjun.name)
    end
  end,
})

return zhenjun
