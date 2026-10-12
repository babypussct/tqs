local zhujian = fk.CreateSkill {
  name = "zhujian",
}

Fk:loadTranslationTable{
  ["zhujian"] = "筑舰",
  [":zhujian"] = "出牌阶段限一次，你可以令至少两名装备区里有牌的角色各摸一张牌。",
  ["#zhujian"] = "筑舰：令至少两名装备区里有牌的角色各摸一张牌",

  ["$zhujian1"] = "修橹筑楼舫，伺时补金瓯。",
  ["$zhujian2"] = "连舫披金甲，王气自可收。",
}

zhujian:addEffect("active", {
  anim_type = "drawcard",
  min_target_num = 2,
  max_target_num = 999,
  prompt = "#zhujian",
  can_use = function(self, player)
    return player:usedSkillTimes(zhujian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #to_select:getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if p:isAlive() then
        p:drawCards(1, zhujian.name)
      end
    end
  end,
})

return zhujian
