
local jianchus = fk.CreateSkill {
  name = "jianchus",
  tags = { Skill.Wake },
  related_skills = { "jige" },
}

Fk:loadTranslationTable{
  ["jianchus"] = "剑出",
  [":jianchus"] = "觉醒技，你在摸牌阶段外累计获得五张牌时，你回复1点体力并获得〖击格〗，本局游戏你所有的【闪】视为【杀】，"..
  "且你阵亡时可以令一名其他角色获得〖砺刃〗。",

  ["#jianchus-choose"] = "剑出：你可以令一名其他角色获得“砺刃”",

  ["$jianchus1"] = "剑者，心之刃也，当斩尽天下不平！",
  ["$jianchus2"] = "三尺青锋在手，江湖又有何惧！",
}

jianchus:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jianchus.name) and player.phase ~= Player.Draw and
      player:usedSkillTimes(jianchus.name, Player.HistoryGame) == 0 then
      local n = player:getMark(jianchus.name)
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          n = n + #move.moveInfo
        end
      end
      return n > 4
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, jianchus.name, 0)
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = jianchus.name,
    }
    if player.dead then return end
    room:handleAddLoseSkills(player, "jige")
    room:setPlayerMark(player, "jianchus_wake", 1)
    player:filterHandcards()
  end,

  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(jianchus.name, true) and
      player:getMark("jianchus_wake") == 0 and player.phase ~= Player.Draw
  end,
  on_refresh = function (self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        n = n + #move.moveInfo
      end
    end
    player.room:addPlayerMark(player, jianchus.name, n)
  end,
})

jianchus:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(jianchus.name) and player:getMark("jianchus_wake") > 0 and card.name == "jink" and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
})

jianchus:addEffect(fk.Death, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianchus.name, false, true) and
      player:getMark("jianchus_wake") > 0 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#jianchus-choose",
      skill_name = jianchus.name,
      cancelable = true,
    })
    if #to > 0 then
      player:broadcastSkillInvoke(jianchus.name)
      room:notifySkillInvoked(player, self.name, "support")
      room:handleAddLoseSkills(to[1], "liren")
    end
  end,
})

return jianchus
