local jielu = fk.CreateSkill {
  name = "jielu",
}

Fk:loadTranslationTable{
  ["jielu"] = "截路",
  [":jielu"] = "出牌阶段，你可以重置一名已横置角色并弃置其一张牌，然后若此回合下一次进入弃牌堆的牌点数大于此弃牌，你对其造成1点伤害。",

  ["#jielu"] = "截路：选择一名横置的角色，弃置弃一张牌",

  ["$jielu1"] = "刘备望风披靡，我等釜底抽薪！",
  ["$jielu2"] = "取兵断其归途，汉王必成瓮中之鳖。",
}

jielu:addEffect("active", {
  anim_type = "control",
  prompt = "#jielu",
  target_num = 1,
  card_num = 0,
  card_filter = Util.FalseFunc,
  can_use = Util.TrueFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.chained and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local skillName = jielu.name
    target:setChainState(false)
    if player.dead or target.dead or target:isNude() then return end
    local num = 0
    if player == target then
      local toDiscard = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        cancelable = false,
        skip = true
      })
      if #toDiscard > 0 then
        num = Fk:getCardById(toDiscard[1]).number
        room:throwCard(toDiscard, skillName, player, player)
      end
    else
      local toDiscard = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = skillName,
      })
      num = Fk:getCardById(toDiscard).number
      room:throwCard(toDiscard, skillName, target, player)
    end
    if num > 0 and not (player.dead or target.dead) then
      room:setPlayerMark(player, "jielu-turn", { target, num })
    end
  end,
})

jielu:addEffect(fk.AfterCardsMove, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jielu.name) and player:getMark("jielu-turn") ~= 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and #move.moveInfo > 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("jielu-turn")
    local to = mark[1]
    local x = mark[2]
    room:setPlayerMark(player, "jielu-turn", 0)
    if to.dead then return end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard.number > x then
            room:damage{
              from = player,
              to = to,
              damage = 1,
              skillName = jielu.name,
            }
            break
          end
        end
      end
    end
  end,
})

jielu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "jielu-turn", 0)
end)

return jielu
