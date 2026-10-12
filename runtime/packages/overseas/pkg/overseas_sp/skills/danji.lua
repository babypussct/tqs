local danji = fk.CreateSkill {
  name = "os__danji",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["os__danji"] = "单骑",
  [":os__danji"] = "觉醒技，准备阶段，若你的手牌数不等于体力值且本局主公不为刘备，你将体力回复至体力上限，获得〖马术〗和〖怒斩〗，"..
  "本局游戏你每回合首次使用转化【杀】结算结束后，你摸一张牌。",

  ["$os__danji1"] = "桃园义犹在，千里又何妨！",
  ["$os__danji2"] = "纵然单刀一骑，亦可破敌千里！",
}

danji:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(danji.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(danji.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() ~= player.hp and
      (player.room:getLord() == nil or
      (not (string.find(player.room:getLord().general, "liubei") or string.find(player.room:getLord().deputyGeneral, "liubei"))))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, danji.name, 1)
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = danji.name,
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "mashu|nuzhan")
  end,
})

danji:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and player:getMark(danji.name) > 0 and
      data.card.trueName == "slash" and data.card:isConverted() then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.card.trueName == "slash" and use.from == player and
          use.card:isConverted()
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke(danji.name)
    player.room:notifySkillInvoked(player, self.name, "drawcard")
    player:drawCards(1, danji.name)
  end,
})

return danji
