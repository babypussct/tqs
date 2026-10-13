local yawang = fk.CreateSkill {
  name = "yawang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yawang"] = "雅望",
  [":yawang"] = "锁定技，摸牌阶段开始时，你放弃摸牌，改为摸X张牌，然后你于出牌阶段内至多使用X张牌（X为与你体力值相等的角色数）。",

  ["@yawang-turn"] = "雅望",

  ["$yawang1"] = "君子，当以正气立于乱世。",
  ["$yawang2"] = "琰，定不负诸位雅望！",
}

yawang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yawang.name) and player.phase == Player.Draw and
      not data.skipped
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p.hp == player.hp then
        n = n + 1
      end
    end
    player.room:addPlayerMark(player, "@yawang-turn", n)
    player:drawCards(n, yawang.name)
  end,
})

yawang:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(yawang.name, Player.HistoryTurn) > 0 and
      player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@yawang-turn", 1)
  end,
})

yawang:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:usedSkillTimes(yawang.name, Player.HistoryTurn) > 0 and player.phase == Player.Play and
      player:getMark("@yawang-turn") == 0
  end,
})

return yawang
