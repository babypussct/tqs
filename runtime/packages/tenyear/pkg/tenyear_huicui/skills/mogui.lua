local mogui = fk.CreateSkill {
  name = "mogui",
}

Fk:loadTranslationTable{
  ["mogui"] = "漠规",
  [":mogui"] = "你的回合内，可以执行以下选项并移除：<br>"..
  "1.判定阶段开始时，令一名角色回复1点体力并弃置判定区所有牌；<br>"..
  "2.摸牌阶段开始时，令一名角色摸牌阶段摸牌数+1，出牌阶段使用【杀】次数+1；<br>"..
  "3.弃牌阶段开始时弃置至多五张牌，令一名角色手牌上限+1并摸等量张牌。",

  ["#mogui-judge"] = "漠规：弃置一名角色判定区的所有牌",
  ["#mogui-phase_judge"] = "漠规：令一名角色回复1点体力并弃置判定区所有牌",
  ["#mogui-phase_draw"] = "漠规：令一名角色摸牌数及使用【杀】次数均+1",
  ["#mogui-phase_discard"] = "漠规：弃置至多5张牌，令一名角色手牌上限+1并摸等量张牌",
  ["@mogui"] = "漠规",

  ["$mogui1"] = "君子言行由心，不拘繁文褥节。",
  ["$mogui2"] = "心猿在役，何以俗规锁意马？"
}

mogui:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(mogui.name) then
      if player.phase == Player.Judge then
        return not table.contains(player:getTableMark("mogui_used"), "judge")
      elseif player.phase == Player.Draw then
        return not table.contains(player:getTableMark("mogui_used"), "draw")
      elseif player.phase == Player.Discard then
        return not table.contains(player:getTableMark("mogui_used"), "discard") and not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Discard then
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 5,
        targets = room.alive_players,
        pattern = ".",
        skill_name = mogui.name,
        prompt = "#mogui-phase_discard",
        cancelable = true,
        will_throw = true,
        no_indicate = true
      })
      if #tos > 0 and #cards > 0 then
        event:setCostData(self, { tos = tos, cards = cards })
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = mogui.name,
        prompt = "#mogui-" .. Util.PhaseStrMapper(player.phase),
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, { tos = to })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = mogui.name
    local to = event:getCostData(self).tos[1]
    if player.phase == Player.Judge then
      room:addTableMark(player, "mogui_used", "judge")
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = skillName
        }
      end
      if not to.dead then
        to:throwAllCards("j", skillName)
      end
      if not to.dead then
        room:setPlayerMark(player, "mogui_prohibit-turn", 1)
      end
    elseif player.phase == Player.Draw then
      room:addTableMark(player, "mogui_used", "draw")
      room:addPlayerMark(to, "@mogui")
      room:addPlayerMark(to, MarkEnum.SlashResidue)
    elseif player.phase == Player.Discard then
      room:addTableMark(player, "mogui_used", "discard")
      local cards = event:getCostData(self).cards ---@type integer[]
      room:throwCard(cards, skillName, player, player)
      if not to.dead then
        room:addPlayerMark(to, MarkEnum.AddMaxCards)
        to:drawCards(#cards, skillName)
      end
    end
  end,
})

mogui:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@mogui") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@mogui")
  end,
})

mogui:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "mogui_used", 0)
end)

return mogui
