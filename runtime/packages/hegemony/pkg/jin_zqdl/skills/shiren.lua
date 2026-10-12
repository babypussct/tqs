local shiren = fk.CreateSkill{
  name = "heg__shiren",
}

Fk:loadTranslationTable{
  ["heg__shiren"] = "识人",
  [":heg__shiren"] = "每回合限一次，当一名未确定势力的其他角色受到伤害后，你可以交给其两张牌并摸两张牌。",

  ["#heg__shiren-invoke"] = "识人：你可以交给 %dest 两张牌并摸两张牌",

  ["$heg__shiren1"] = "宠过必乱，不可大任。",
  ["$heg__shiren2"] = "开卷有益，识人有法",
}

shiren:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(shiren.name) and
      not target.dead and target.kingdom == "unknown" and #player:getCardIds("he") > 1 and
      player:usedSkillTimes(shiren.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = shiren.name,
      prompt = "#heg__shiren-invoke::"..target.id,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, target, fk.ReasonGive, shiren.name, nil, false, player)
    if not player.dead then
      player:drawCards(2, shiren.name)
    end
  end,
})

shiren:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return shiren

