local xuetuV3 = fk.CreateSkill {
  name = "xuetu_v3",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["xuetu_v3"] = "血途",
  [":xuetu_v3"] = "转换技，出牌阶段限一次，你可以：阳，回复1点体力并令一名角色弃置两张牌；阴，摸一张牌并对一名角色造成1点伤害。",

  ["#xuetu_v3_yang"] = "血途：你可回复1点体力并令一名角色弃两张牌",
  ["#xuetu_v3_yin"] = "血途：你可摸一张牌并对一名角色造成1点伤害",

  ["$xuetu_v31"] = "徐、扬粮草甚多，众将随我前往。",
  ["$xuetu_v32"] = "哈哈哈哈，所过之处，粒粟不留。",
}

xuetuV3:addEffect("active", {
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function(self, player)
    return "#xuetu_v3_" .. player:getSwitchSkillState(xuetuV3.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(xuetuV3.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = xuetuV3.name
    local player = effect.from
    local target = effect.tos[1]

    if player:getSwitchSkillState(skillName, true) == fk.SwitchYang then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }

      room:askToDiscard(
        target,
        {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
        }
      )
    else
      player:drawCards(1, skillName)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return xuetuV3
