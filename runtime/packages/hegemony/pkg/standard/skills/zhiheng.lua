local zhiheng = fk.CreateSkill{
  name = "hs__zhiheng",
}

Fk:loadTranslationTable{
  ["hs__zhiheng"] = "制衡",
  [":hs__zhiheng"] = "出牌阶段限一次，你可弃置至多X张牌（X为你的体力上限），然后你摸等量的牌。",

  ["$hs__zhiheng1"] = "容我三思。",
  ["$hs__zhiheng2"] = "且慢。",
}

zhiheng:addEffect("active", {
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(zhiheng.name, Player.HistoryPhase) == 0
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function(self, player)
    return table.find(player:getEquipments(Card.SubtypeTreasure), function(cid)
      return Fk:getCardById(cid).name == "luminous_pearl"
    end) and 998 or player.maxHp
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected >= player.maxHp then
      return table.find(player:getEquipments(Card.SubtypeTreasure), function(cid)
        return Fk:getCardById(cid).name == "luminous_pearl" and not table.contains(selected, cid) and to_select ~= cid
      end)
    end
    return #selected < player.maxHp and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local from = effect.from
    room:throwCard(effect.cards, zhiheng.name, from, from)
    if not from.dead then
      from:drawCards(#effect.cards, zhiheng.name)
    end
  end
})

return zhiheng
