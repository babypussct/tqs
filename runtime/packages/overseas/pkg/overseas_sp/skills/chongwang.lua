local chongwang = fk.CreateSkill({
  name = "os__chongwang",
  tags = { Skill.Lord },
})

Fk:loadTranslationTable{
  ["os__chongwang"] = "崇望",
  [":os__chongwang"] = "主公技，每名其他群势力角色限一次，其出牌阶段开始时，可以交给你一张牌，然后你与其使用【杀】或伤害类锦囊牌"..
  "不能指定对方为目标直到你下回合结束。",

  ["#os__chongwang-invoke"] = "崇望：你可以交给 %src 一张牌，直到其下回合结束双方伤害牌不能指定对方为目标",
}

chongwang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(chongwang.name) and target.phase == Player.Play and
      target.kingdom == "qun" and not target:isNude() and not table.contains(player:getTableMark(chongwang.name), target)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chongwang.name,
      prompt = "#os__chongwang-invoke:"..player.id,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, chongwang.name, target)
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonGive, chongwang.name, nil, false, target)
    if not player.dead then
      room:addTableMark(player, "os__chongwang_targets", target)
    end
  end,
})

chongwang:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "os__chongwang_targets", 0)
  end,
})

chongwang:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return card and card.is_damage_card and from and to and
      (table.contains(from:getTableMark("os__chongwang_targets"), to) or
      table.contains(to:getTableMark("os__chongwang_targets"), from))
  end,
})

chongwang:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, chongwang.name, 0)
end)

return chongwang
