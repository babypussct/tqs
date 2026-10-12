local rengou_active = fk.CreateSkill{
  name = "rengou&",
}

Fk:loadTranslationTable{
  ["rengou&"] = "仁彀",
  [":rengou&"] = "你可以弃置1张牌并令威刘备回复1点体力，然后其可以令你发动一次至多摸2张牌的〖烈骧〗。",

  ["#rengou&"] = "仁彀：弃置一张牌并令威刘备回复1点体力，其可以令你发动一次“烈骧”",
  ["#rengou-invoke"] = "仁彀：是否允许 %src 发动一次“烈骧”？",
}

rengou_active:addEffect("active", {
  mute = true,
  prompt = "#rengou&",
  card_num = 1,
  target_num = 1,
  can_use = function (self, player)
    return player.kingdom == "shu" and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p:hasSkill("rengou") and p:usedSkillTimes("rengou", Player.HistoryPhase) == 0
      end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return to_select:hasSkill("rengou") and to_select:usedSkillTimes("rengou", Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:addSkillUseHistory("rengou", 1)
    target:broadcastSkillInvoke("rengou")
    room:notifySkillInvoked(target, "rengou", "support")
    room:throwCard(effect.cards, "rengou", player, player)
    if target.dead then return end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = "rengou",
    }
    if player.dead or target.dead then return end
    if room:askToSkillInvoke(target, {
      skill_name = "rengou",
      prompt = "#rengou-invoke:"..player.id,
    }) then
      room:doIndicate(target, { player })
      room:setPlayerMark(player, "rengou-tmp", 1)
      room:askToUseActiveSkill(player, {
        skill_name = "liexiang",
        prompt = "#liexiang:::"..math.min(#room.players, 2),
      })
      room:setPlayerMark(player, "rengou-tmp", 0)
    end
  end,
})

return rengou_active
