local mExGongqi = fk.CreateSkill {
  name = "m_ex__gongqi",
}

Fk:loadTranslationTable{
  ["m_ex__gongqi"] = "弓骑",
  [":m_ex__gongqi"] = "若你的装备区内有坐骑牌，则你的攻击范围无限；出牌阶段限一次，你可以弃置一张非基本牌，并选择一名有牌的其他角色，弃置其一张牌。",

  ["#m_ex__gongqi"] = "弓骑：你可弃一张非基本牌，弃置一名其他角色的一张牌",

  ["$m_ex__gongqi1"] = "一弦射三矢，无一不中敌！",
  ["$m_ex__gongqi2"] = "临阵能左右开弓，上马使刀枪无对！",
}

mExGongqi:addEffect("active", {
  anim_type = "control",
  prompt = "#m_ex__gongqi",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(mExGongqi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select)
    return to_select ~= player and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = mExGongqi.name
    local player = effect.from
    local to = effect.tos[1]
    room:throwCard(effect.cards, skillName, player, player)
    if not (player:isAlive() and to:isAlive()) and not to:isNude() then
      return
    end

    local id = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "he",
        skill_name = skillName,
      }
    )
    room:throwCard(id, skillName, to, player)
  end,
})

mExGongqi:addEffect("atkrange", {
  correct_func = function (self, from, to)
    if
      from:hasSkill(mExGongqi.name) and
      (from:getEquipment(Card.SubtypeDefensiveRide) or from:getEquipment(Card.SubtypeOffensiveRide))
    then
      return 999
    end
  end,
})

return mExGongqi
