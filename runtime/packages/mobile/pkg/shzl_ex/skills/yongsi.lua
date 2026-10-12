local yongsi = fk.CreateSkill{
  name = "m_ex__yongsi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__yongsi"] = "庸肆",
  [":m_ex__yongsi"] = "锁定技，摸牌阶段，你改为摸X张牌（X为全场势力数）；弃牌阶段开始时，你需弃置一张牌，否则失去1点体力。",

  ["#m_ex__yongsi-discard"] = "庸肆：你需弃置一张牌，否则失去1点体力",

  ["$m_ex__yongsi1"] = "乱世之中，必出枭雄。",
  ["$m_ex__yongsi2"] = "得此玉玺，是为天助！",
}

yongsi:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yongsi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    data.n = #kingdoms
  end,
})

yongsi:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yongsi.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isNude() or #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = yongsi.name,
      prompt = "#m_ex__yongsi-discard",
      cancelable = true,
    }) == 0 then
      room:loseHp(player, 1, yongsi.name)
    end
  end,
})

return yongsi
