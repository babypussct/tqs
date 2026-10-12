local zhenjun = fk.CreateSkill {
  name = "ol_ex__zhenjun",
}

Fk:loadTranslationTable{
  ["ol_ex__zhenjun"] = "镇军",
  [":ol_ex__zhenjun"] = "准备阶段，你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1），然后选择一项："..
  "1.你弃置与其中非装备牌数等量的牌；2.结束阶段，其摸与其中非装备牌数等量的牌。",

  ["#ol_ex__zhenjun-choose"] = "镇军：选择一名角色，弃置其手牌数减体力值张牌（至少一张）",
  ["#ol_ex__zhenjun-card"] = "镇军：弃置 %dest %arg张牌，然后选择弃牌或令其摸牌",
  ["#ol_ex__zhenjun-discard"] = "镇军：弃置%arg张牌，或点“取消” %dest 于结束阶段摸%arg张牌",
  ["@ol_ex__zhenjun-turn"] = "镇军",

  ["$ol_ex__zhenjun1"] = "奉令无犯，当敌制决，靡有遗失！",
  ["$ol_ex__zhenjun2"] = "军令在此，围而后降者皆不赦。",
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
      not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end

    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhenjun.name,
      prompt = "#ol_ex__zhenjun-choose",
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
    local num = math.min(math.max(1, to:getHandcardNum() - to.hp), #to:getCardIds("he"))
    local cards
    if to == player then
      cards = room:askToDiscard(player, {
        min_num = num,
        max_num = num,
        include_equip = true,
        skill_name = zhenjun.name,
        cancelable = false,
        prompt = "#ol_ex__zhenjun-card::"..to.id..":"..num,
        skip = true,
      })
    else
      cards = room:askToChooseCards(player, {
        target = to,
        min = num,
        max = num,
        flag = "he",
        skill_name = zhenjun.name,
        prompt = "#ol_ex__zhenjun-card::"..to.id..":"..num
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
        prompt = "#ol_ex__zhenjun-discard::"..to.id..":"..num,
      }) == 0 then
      room:addPlayerMark(to, "@ol_ex__zhenjun-turn", num)
    end
  end,
})

zhenjun:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and player:getMark("@ol_ex__zhenjun-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@ol_ex__zhenjun-turn")
    room:setPlayerMark(player, "@ol_ex__zhenjun-turn", 0)
    player:drawCards(x, zhenjun.name)
  end,
})

return zhenjun
