local dinglun = fk.CreateSkill{
  name = "dinglun",
  related_skills = { "quxig" },
}

Fk:loadTranslationTable{
  ["dinglun"] = "定论",
  [":dinglun"] = "出牌阶段限一次，你可以选择至多半数角色（向上取整），若这些角色的手牌数之和大于其他角色手牌数之和，"..
    "这些角色获得〖趋袭〗至你下一个准备阶段并摸一张牌。",

  ["#dinglun"] = "定论：选择至多%arg名角色",

  ["$dinglun1"] = "",
  ["$dinglun2"] = "",
}

dinglun:addEffect("active", {
  anim_type = "support",
  prompt = function(self, player)
    return "#dinglun:::"..tostring((#Fk:currentRoom().alive_players+1)//2)
  end,
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(dinglun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < #Fk:currentRoom().alive_players/2
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local x, y = 0, 0
    for _, p in ipairs(effect.tos) do
      x = x + p:getHandcardNum()
    end
    for _, p in ipairs(room.alive_players) do
      y = y + p:getHandcardNum()
    end
    if x > y/2 then
      room:sortByAction(effect.tos)
      for _, p in ipairs(effect.tos) do
        if player.dead then break end
        if not p.dead and not p:hasSkill("quxig", true) then
          room:setPlayerMark(p, "dinglunFrom", player)
          room:handleAddLoseSkills(p, "quxig")
        end
        if not p.dead then
          p:drawCards(1, dinglun.name)
        end
      end
    end
  end,
})

dinglun:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("dinglunFrom") == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "dinglunFrom", 0)
    room:handleAddLoseSkills(player, "-quxig")
  end,
})

dinglun:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target.phase == Player.Start and player:getMark("dinglunFrom") == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "dinglunFrom", 0)
    room:handleAddLoseSkills(player, "-quxig")
  end,
})

dinglun:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.skill.name == "quxig" and player:getMark("dinglunFrom") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "dinglunFrom", 0)
  end,
})

return dinglun
