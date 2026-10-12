
local dushou_active = fk.CreateSkill{
  name = "m_heg__dushou_active&",
}

Fk:loadTranslationTable{
  ["m_heg__dushou_active&"] = "督授",
  [":m_heg__dushou_active&"] = "出牌阶段限一次，你可以弃置至多两张牌，令君孙权摸等量的牌。",

  ["#m_heg__dushou"] = "督授：弃置至多两张牌，令君孙权摸等量的牌",
}

dushou_active:addEffect("active", {
  mute = true,
  prompt = "#m_heg__dushou",
  min_card_num = 1,
  max_card_num = 2,
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill("m_heg__dushou") and p:usedSkillTimes("m_heg__dushou", Player.HistoryPhase) == 0
    end)
  end,
  target_num = function (self, player)
    local targets = table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill("m_heg__dushou") and p:usedSkillTimes("m_heg__dushou", Player.HistoryPhase) == 0
    end)
    if #targets > 1 then
      return 1
    else
      return 0
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    local targets = table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill("m_heg__dushou") and p:usedSkillTimes("m_heg__dushou", Player.HistoryPhase) == 0
    end)
    if #targets > 1 then
      return #selected == 0
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target
    if #effect.tos > 0 then
      target = effect.tos[1]
    else
      target = table.find(room.alive_players, function (p)
        return p:hasSkill("m_heg__dushou") and p:usedSkillTimes("m_heg__dushou", Player.HistoryPhase) == 0
      end)  ---@cast target ServerPlayer
    end
    target:addSkillUseHistory("m_heg__dushou", 1)
    target:broadcastSkillInvoke("m_heg__dushou")
    room:notifySkillInvoked(target, "m_heg__dushou", "support")
    room:throwCard(effect.cards, "m_heg__dushou", player, player)
    if not target.dead then
      target:drawCards(#effect.cards, "m_heg__dushou")
    end
  end
})

return dushou_active
