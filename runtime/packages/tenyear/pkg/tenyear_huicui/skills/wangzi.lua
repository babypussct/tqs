local wangzi = fk.CreateSkill{
  name = "wangzi",
}

Fk:loadTranslationTable{
  ["wangzi"] = "望资",
  [":wangzi"] = "每轮限一次，其他角色的出牌阶段开始时，你可以弃置至多五张牌，令其从牌堆获得等量黑色牌，"..
    "此阶段其使用这些牌后你与其各摸一张牌。",

  ["#wangzi-invoke"] = "望资：你可以弃置至多%arg张牌，令 %dest 获得等量黑色牌，其此阶段使用这些牌后你与其各摸一张牌",
  ["@@wangzi-phase"] = "望资",

  ["$wangzi1"] = "妾有一吻，欲赏英雄。",
  ["$wangzi2"] = "倾我所有，给君所需。",
}

wangzi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player ~= target and player:hasSkill(wangzi.name) and target.phase == Player.Play and
      player:usedEffectTimes(wangzi.name, Player.HistoryRound) == 0 and
      not (target.dead or player:isNude())
  end,
  on_cost  = function(self, event, target, player, data)
    local room = player.room
    --local n = math.min((player:getHandcardNum() + 1) // 2, 5)
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 5,
      include_equip = true,
      skill_name = wangzi.name,
      cancelable = true,
      prompt = "#wangzi-invoke::"..target.id..":5",
      skip = true
    })
    if #cards > 0 then
      event:setCostData(self, { tos = { target }, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    room:throwCard(cards, wangzi.name, player, player)
    if target.dead then return end
    local ids = room:getCardsFromPileByRule(".|.|black", #cards)
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, target, fk.ReasonJustMove, wangzi.name, nil, false, target,
        { "@@wangzi-phase", { player.id, target.id } })
    end
  end,
})

wangzi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local infos = data.subcardsFromInfo
    return infos and #infos > 0 and table.every(infos, function(info)
      local mark = info.beforeCard:getMark("@@wangzi-phase")
      return type(mark) == "table" and mark[1] == player.id and mark[2] == target.id
    end)
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, wangzi.name)
    if not player.dead then
      player:drawCards(1, wangzi.name)
    end
  end,
})

return wangzi
