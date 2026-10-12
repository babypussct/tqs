local chengzhang = fk.CreateSkill {
  name = "chengzhang",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["chengzhang"] = "成章",
  [":chengzhang"] = "觉醒技，准备阶段，若你造成的伤害与受到的伤害值之和累计7点或以上，则你回复1点体力并摸1张牌，"..
  "然后修改〖酒诗〗（获得锦囊牌的效果改为当你翻面后发动）。",

  ["@chengzhang"] = "成章",

  ["$chengzhang1"] = "弦急悲声发，聆我慷慨言。",
  ["$chengzhang2"] = "盛时不再来，百年忽我遒。",
}

chengzhang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengzhang.name) and
      player:usedSkillTimes(chengzhang.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@chengzhang") > 6
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@chengzhang", 0)
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = chengzhang.name
      })
    end
    if not player.dead then
      player:drawCards(1, chengzhang.name)
      if player:hasSkill("m_ex__jiushi", true) then
        player.room:setPlayerMark(player, "m_ex__jiushi_upgrade", 1)
      end
    end
  end,
})

chengzhang:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengzhang.name, true) and
    player:usedSkillTimes(chengzhang.name, Player.HistoryGame) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@chengzhang", 1)
  end,
})

chengzhang:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengzhang.name, true) and
    player:usedSkillTimes(chengzhang.name, Player.HistoryGame) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@chengzhang", data.damage)
  end,
})

chengzhang:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@chengzhang", 0)
end)

return chengzhang
