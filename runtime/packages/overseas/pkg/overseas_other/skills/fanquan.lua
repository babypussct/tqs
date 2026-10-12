local fanquan = fk.CreateSkill {
  name = "os__fanquan",
}

Fk:loadTranslationTable{
  ["os__fanquan"] = "反拳",
  [":os__fanquan"] = "当你受到伤害后，你可以对一名其他角色造成1点伤害。"..
  "<a href='os__wrestle'>搏击</a>：再对其造成X点伤害（X为此伤害值），本回合你计算与其他角色距离+1。",

  ["#os__fanquan-choose"] = "反拳：对一名角色造成1点伤害，若“搏击”则再造成伤害",
  ["os__fanquan_wrestle"] = "搏击",
}

Fk:addTargetTip{
  name = fanquan.name,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    if player:inMyAttackRange(to_select) and to_select:inMyAttackRange(player) then
      return "os__fanquan_wrestle"
    end
  end,
}

fanquan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fanquan.name) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = fanquan.name,
      prompt = "#os__fanquan-choose",
      cancelable = true,
      target_tip_name = fanquan.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local yes = player:inMyAttackRange(to) and to:inMyAttackRange(player)
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = fanquan.name,
    }
    if yes and not player.dead and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = data.damage,
        skillName = fanquan.name,
      }
      if not player.dead then
        room:addPlayerMark(player, "os__fanquan-turn", 1)
      end
    end
  end,
})

fanquan:addEffect("distance", {
  correct_func = function(self, from, to)
    return from:getMark("os__fanquan-turn")
  end,
})

return fanquan
