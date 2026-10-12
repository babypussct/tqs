local shepan = fk.CreateSkill {
  name = "shepan",
}

Fk:loadTranslationTable{
  ["shepan"] = "慑叛",
  [":shepan"] = "每轮每种牌名限一次，每回合限一次，当你成为其他角色使用伤害类牌的目标后，你可以选择一项：1.摸一张牌；"..
  "2.将其一张手牌置于牌堆顶。然后若你与其手牌数相同，此牌对你无效。",

  ["shepan_put"] = "将%dest一张手牌置于牌堆顶",

  ["$shepan1"] = "贼寇来攻，积弩俱发破其攻势。",
  ["$shepan2"] = "叛军欲出，引兵设伏灭其战意。",
}

shepan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shepan.name) and
      data.from ~= player and data.card.is_damage_card and
      not table.contains(player:getTableMark("shepan-round"), data.card.trueName) and
      player:usedSkillTimes(shepan.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "draw1", "Cancel" }
    if not data.from:isKongcheng() then
      table.insert(choices, 2, "shepan_put::"..data.from.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shepan.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "shepan-round", data.card.trueName)
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      player:drawCards(1, shepan.name)
    else
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "h",
        skill_name = shepan.name,
      })
      room:moveCardTo(id, Card.DrawPile, nil, fk.ReasonPut, shepan.name, nil, false, player)
    end
    if player:getHandcardNum() == data.from:getHandcardNum() then
      data.nullified = true
    end
  end,
})

return shepan
