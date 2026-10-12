local yinglue = fk.CreateSkill {
  name = "yinglue",
  max_branches_use_time = {
    ["yinglue1"] = {
      [Player.HistoryPhase] = 1
    },
    ["yinglue2"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["yinglue"] = "英略",
  [":yinglue"] = "出牌阶段各限一次，你可以令一名角色：1.失去1点体力，其下个摸牌阶段摸牌数+2；2.摸两张牌，其下个弃牌阶段手牌上限-2。",

  ["#yinglue"] = "英略：选择一项令一名角色执行",
  ["yinglue1"] = "失去1点体力，下个摸牌阶段摸牌数+2",
  ["yinglue2"] = "摸两张牌，下个弃牌阶段手牌上限-2",
  ["@yinglue1"] = "摸牌数+",
  ["@yinglue2"] = "手牌上限-",

  ["$yinglue1"] = "盟堪市肆，近宅兴家，醉宾客而能贵东主。",
  ["$yinglue2"] = "势如明渠，决川距海，活支流然尽注五湖。",
}

yinglue:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "yinglue-phase", 0)
end)

yinglue:addEffect("active", {
  anim_type = "control",
  prompt = "#yinglue",
  card_num = 0,
  target_num = 1,
  interaction = UI.OptionBox { options = { "yinglue1", "yinglue2" }, direct_send = true },
  can_use = function(self, player)
    return player:usedSkillTimes(yinglue.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets)
    if #selected_targets == 0 then return {} end
    return #selected_targets == 0 and {} or table.filter({ "yinglue1", "yinglue2" }, function(choice)
      return yinglue:withinBranchTimesLimit(player, choice, Player.HistoryPhase)
    end)
  end,
  history_branch = function(self, player, data)
    return self.interaction.data
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if self.interaction.data == "yinglue1" then
      room:loseHp(target, 1, yinglue.name)
      if not target.dead then
        room:addPlayerMark(target, "@yinglue1", 2)
      end
    else
      target:drawCards(2, yinglue.name)
      if not target.dead then
        room:addPlayerMark(target, "@yinglue2", 2)
      end
    end
  end,
})

yinglue:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@yinglue1") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@yinglue1")
  end,
})

yinglue:addEffect(fk.EventPhaseEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if player.phase == Player.Draw then
        return player:getMark("@yinglue1") > 0
      elseif player.phase == Player.Discard then
        return player:getMark("@yinglue2") > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if player.phase == Player.Draw then
      player.room:setPlayerMark(player, "@yinglue1", 0)
    elseif player.phase == Player.Discard then
      player.room:setPlayerMark(player, "@yinglue2", 0)
    end
  end,
})

yinglue:addEffect("maxcards", {
  correct_func = function(self, player)
    if player.phase == Player.Discard then
      return -player:getMark("@yinglue2")
    end
  end,
})

return yinglue
