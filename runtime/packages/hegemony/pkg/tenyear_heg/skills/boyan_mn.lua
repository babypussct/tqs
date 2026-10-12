
local boyan = fk.CreateSkill{
  name = "ty_heg__boyan_manoeuvre",
}

Fk:loadTranslationTable{
  ["ty_heg__boyan_manoeuvre"] = "驳言⇋",
  [":ty_heg__boyan_manoeuvre"] = "出牌阶段限一次，你可选择一名其他角色，其本回合不能使用或打出手牌。",

  ["#ty_heg__boyan_manoeuvre"] = "驳言：令一名角色本回合不能使用或打出手牌",
}

boyan:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_heg__boyan_manoeuvre",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(boyan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    room:setPlayerMark(effect.tos[1], "@@ty_heg__boyan-turn", 1)
  end,
})

boyan:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_heg__boyan_manoeuvre", true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-ty_heg__boyan_manoeuvre", nil, false, true)
    room:setPlayerMark(player, "@@ty_heg__boyan_manoeuvre", 0)
  end,
})

return boyan