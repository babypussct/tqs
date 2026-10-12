
local fenxun = fk.CreateSkill {
  name = "m_heg__fenxun",
}

Fk:loadTranslationTable{
  ["m_heg__fenxun"] = "奋迅",
  [":m_heg__fenxun"] = "出牌阶段开始时，你可以选择一名其他角色，本回合你计算与其的距离视为1。",

  ["#m_heg__fenxun-choose"] = "奋迅：选择一名角色，本回合你计算与其的距离视为1",

  ["$m_heg__fenxun1"] = "取封侯爵赏，正在今日！",
  ["$m_heg__fenxun2"] = "给我拉过来！",
}

fenxun:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenxun.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, true) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, true),
      min_num = 1,
      max_num = 1,
      skill_name = fenxun.name,
      prompt = "#m_heg__fenxun-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:addTableMarkIfNeed(player, "m_heg__fenxun-turn", to)
  end,
})

fenxun:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("m_heg__fenxun-turn"), to) then
      return 1
    end
  end,
})

return fenxun
