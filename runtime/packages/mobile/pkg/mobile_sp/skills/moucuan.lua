local moucuan = fk.CreateSkill {
  name = "moucuan",
  tags = { Skill.Wake },
  related_skills = { "binghuo" },
}

Fk:loadTranslationTable{
  ["moucuan"] = "谋篡",
  [":moucuan"] = "觉醒技，准备阶段，若你的“兵”数不少于X张（X为场上势力数），你减少1点体力值上限，然后获得技能〖兵祸〗。",

  ["$moucuan1"] = "汉失民心，天赐良机！",
  ["$moucuan2"] = "天下正主，正是大贤良师！",
}

moucuan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(moucuan.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(moucuan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    return #player:getPile("mayuanyi_bing") >= #kingdoms
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isAlive() then
      room:handleAddLoseSkills(player, "binghuo", nil, true, false)
    end
  end,
})

return moucuan
