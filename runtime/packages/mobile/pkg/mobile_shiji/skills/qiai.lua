local qiai = fk.CreateSkill {
  name = "wisdom__qiai",
}

Fk:loadTranslationTable{
  ["wisdom__qiai"] = "七哀",
  [":wisdom__qiai"] = "出牌阶段限一次，你可以将一张非基本牌交给一名其他角色，然后其选择一项：1.令你回复1点体力；2.令你摸两张牌。",

  ["#wisdom__qiai"] = "七哀：将一张非基本牌交给一名角色，其选择令你回复体力或摸牌",
  ["#wisdom__qiai-choose"] = "七哀：请选择一项令 %src 执行",

  ["$wisdom__qiai1"] = "亲戚对我悲，朋友相追攀。",
  ["$wisdom__qiai2"] = "出门无所见，白骨蔽平原。",
}

qiai:addEffect("active", {
  anim_type = "support",
  prompt = "#wisdom__qiai",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(qiai.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, qiai.name, nil, true, player)
    if player.dead or target.dead then return end
    local choices = { "draw2" }
    if player:isWounded() then
      table.insert(choices, 1, "recover")
    end

    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = qiai.name,
      prompt = "#wisdom__qiai-choose:"..player.id,
    })
    if choice == "draw2" then
      player:drawCards(2, qiai.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = target,
        skillName = qiai.name,
      })
    end
  end,
})

return qiai
