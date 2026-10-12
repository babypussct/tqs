local luminousPearlSkill = fk.CreateSkill{
  name = "luminous_pearl_skill",
  attached_equip = "luminous_pearl",
}
luminousPearlSkill:addEffect("active", {
  can_use = function(self, player)
    return player:usedSkillTimes(luminousPearlSkill.name, Player.HistoryPhase) == 0
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function(self, player)
    return player.maxHp
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player.maxHp and not player:prohibitDiscard(Fk:getCardById(to_select)) and Fk:getCardById(to_select).name ~= "luminous_pearl"
  end,
  on_use = function(self, room, effect)
    local from = effect.from
    room:notifySkillInvoked(from, "luminous_pearl", "drawcard")
    room:throwCard(effect.cards, self.name, from, from)
    if not from.dead then
      from:drawCards(#effect.cards, self.name)
    end
  end
})
local LP_can_refresh = function(self, event, target, player, data)
  local skill = data.skill
  return player == target and (skill == Fk.skills["hs__zhiheng"] or skill == Fk.skills["lord__zhiheng"]
    or skill == Fk.skills["wk_heg__zhiheng"]) and table.find(player:getEquipments(Card.SubtypeTreasure), function(cid)
      return Fk:getCardById(cid).name == "luminous_pearl"
  end)
end
luminousPearlSkill:addEffect(fk.EventAcquireSkill, {
  can_refresh = LP_can_refresh,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-luminous_pearl_skill", nil, false, true)
  end,
})
luminousPearlSkill:addEffect(fk.EventLoseSkill, {
  can_refresh = LP_can_refresh,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "luminous_pearl_skill", nil, false, true)
  end,
})

Fk:loadTranslationTable{
  ["luminous_pearl_skill"] = "制衡",
  [":luminous_pearl_skill"] = "出牌阶段限一次，你可弃置至多X张牌（X为你的体力上限），然后你摸等量的牌。<font color='grey'><small>此为【制衡（定澜夜明珠）】</small></font>",
}

return luminousPearlSkill
