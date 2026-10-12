local xuetuV2 = fk.CreateSkill {
  name = "xuetu_v2",
}

Fk:loadTranslationTable{
  ["xuetu_v2"] = "血途",
  [":xuetu_v2"] = "出牌阶段各限一次，你可以选择一项：1.令一名角色回复1点体力；2.令一名角色摸两张牌。",

  ["xuetu_v2_recover"] = "令一名角色回复1点体力",
  ["xuetu_v2_draw"] = "令一名角色摸两张牌",
}

xuetuV2:addEffect("active", {
  card_num = 0,
  target_num = 1,
  mute = true,
  interaction = function(self, player)
    local options = { "xuetu_v2_recover", "xuetu_v2_draw" }
    local choices = table.filter(
      options,
      function(option)
        return not table.contains(player:getTableMark("xuetu_v2_used-phase"), option)
      end
    )
    return UI.ComboBox { choices = choices, all_choices = options }
  end,
  can_use = function(self, player)
    return #player:getTableMark("xuetu_v2_used-phase") < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return
      #selected == 0 and
      not (self.interaction.data == "xuetu_v2_recover" and not to_select:isWounded())
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = xuetuV2.name
    local player = effect.from
    player:broadcastSkillInvoke("xuetu")
    room:notifySkillInvoked(player, skillName, "support")
    local target = effect.tos[1]

    room:addTableMarkIfNeed(player, "xuetu_v2_used-phase", self.interaction.data)

    if self.interaction.data == "xuetu_v2_recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    else
      target:drawCards(2, skillName)
    end
  end,
})

return xuetuV2
