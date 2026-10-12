local zhuangrong = fk.CreateSkill{
  name = "ty_heg__zhuangrong",
  related_skills = { "ty_heg_lvlingqi__wushuang" },
}

Fk:loadTranslationTable{
  ["ty_heg__zhuangrong"] = "妆戎",
  [":ty_heg__zhuangrong"] = "出牌阶段限一次，你可以弃置一张锦囊牌，然后你本阶段获得技能〖无双〗。",

  ["#ty_heg__zhuangrong"] = "妆戎：弃置一张锦囊牌，本阶段获得“无双”",

  ["$ty_heg__zhuangrong1"] = "继父神威，无坚不摧！",
  ["$ty_heg__zhuangrong2"] = "我乃温侯吕奉先之女！",
}

zhuangrong:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_heg__zhuangrong",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhuangrong.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeTrick and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, zhuangrong.name, player, player)
    if player.dead then return end
    if not player:hasSkill("ty_heg_lvlingqi__wushuang", true) then
      room:handleAddLoseSkills(player, "ty_heg_lvlingqi__wushuang")
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-ty_heg_lvlingqi__wushuang")
      end)
    end
  end,
})

return zhuangrong

