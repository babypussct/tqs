local osGongsun = fk.CreateSkill {
  name = "os__gongsun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__gongsun"] = "共损",
  [":os__gongsun"] = "锁定技，出牌阶段开始时，你选择攻击范围内的一名角色并选择一种花色，直至你的下个回合开始前，你与其无法使用、打出或弃置该花色的手牌。",

  ["#os__gongsun-target"] = "共损：请选择攻击范围内的一名角色",
  ["#os__gongsun-suit"] = "共损：请选择一种花色，直至你的下个回合开始前，你和 %src 无法使用、打出或弃置该花色的手牌。",
  ["@os__gongsun"] = "共损",

  ["$os__gongsun1"] = "我岂能与魏延这种莽夫共事！",
  ["$os__gongsun2"] = "早知如此，投靠魏国又如何！",
}

osGongsun:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osGongsun.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osGongsun.name
    local room = player.room
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:inMyAttackRange(p)
    end)
    if #availableTargets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__gongsun-target",
        skill_name = skillName,
        cancelable = false,
      }
    )
    if #tos > 0 then
      local to = tos[1]
      local choice = room:askToChoice(
        player,
        {
          choices = { "log_spade", "log_club", "log_heart", "log_diamond" },
          skill_name = skillName,
          prompt = "#os__gongsun-suit:" .. to.id,
        }
      )

      room:addTableMarkIfNeed(player, "_os__gongsun", to.id)
      for _, p in ipairs({ player, to }) do
        room:addTableMark(p, "@os__gongsun", choice)
      end
    end
  end,
})

osGongsun:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__gongsun") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__gongsun", 0)
    table.forEach(table.map(player:getMark("_os__gongsun"), function(pid)
      return room:getPlayerById(pid)
    end), function(p)
      room:setPlayerMark(p, "@os__gongsun", 0)
    end)
  end,
})

osGongsun:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return
      table.contains(player:getTableMark("@os__gongsun"), card:getSuitString(true)) and
      table.contains(player:getCardIds("h"), card.id)
  end,
  prohibit_response = function(self, player, card)
    return
      table.contains(player:getTableMark("@os__gongsun"), card:getSuitString(true)) and
      table.contains(player:getCardIds("h"), card.id)
  end,
  prohibit_discard = function(self, player, card)
    return
      table.contains(player:getTableMark("@os__gongsun"), card:getSuitString(true)) and
      table.contains(player:getCardIds("h"), card.id)
  end,
})

osGongsun:addLoseEffect(function(self, player, is_death)
  if is_death then
    local room = player.room
    room:setPlayerMark(player, "@os__gongsun", 0)
    table.forEach(player:getTableMark("_os__gongsun"), function(pid)
      room:setPlayerMark(room:getPlayerById(pid), "@os__gongsun", 0)
    end)
  end
end)

return osGongsun
