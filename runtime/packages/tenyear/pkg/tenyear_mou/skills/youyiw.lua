
local youyiw = fk.CreateSkill {
  name = "youyiw",
  max_branches_use_time = {
    ["card"] = {
      [Player.HistoryTurn] = 1
    },
    ["hp"] = {
      [Player.HistoryTurn] = 1
    },
  },
}

Fk:loadTranslationTable{
  ["youyiw"] = "诱夷",
  [":youyiw"] = "每回合每项限一次，你成为其他角色使用牌的目标时，你可以令其本阶段使用【杀】次数上限+1，然后你选择一项执行："..
  "1.弃置任意张牌并摸一张牌，本回合结束时摸等量张牌；2.失去至多4点体力并令一名角色摸等量张牌，本回合结束时回复以此法失去的体力。",

  ["#youyiw-invoke"] = "诱夷：你可以令 %dest 本阶段使用【杀】次数+1，你选择执行一项",
  ["youyiw_card"] = "弃置任意张牌并摸一张牌，回合结束摸牌",
  ["youyiw_hp"] = "失去体力并令角色摸牌，回合结束回复体力",
  ["#youyiw-discard"] = "诱夷：弃置任意张牌并摸一张牌，回合结束时摸等量牌",
  ["#youyiw-hp"] = "诱夷：失去至多4点体力并令一名角色摸等量牌，回合结束时回复等量体力",

  ["$youyiw1"] = "败名一人担之，全胜三军同享！",
  ["$youyiw2"] = "蛮兵势大，不可力敌，撤！",
}

youyiw:addAuxActiveSkill("#youyiw_active", {
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = math.min(4, player.hp),
    }
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
})

youyiw:addEffect(fk.TargetConfirming, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(youyiw.name) and
      data.from and data.from ~= player and not data.from.dead and
      (youyiw:withinBranchTimesLimit(player, "hp", Player.HistoryTurn) or
      youyiw:withinBranchTimesLimit(player, "card", Player.HistoryTurn))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "youyiw_card", "youyiw_hp" }
    local choices = table.filter(all_choices, function (choice)
      return youyiw:withinBranchTimesLimit(player, string.sub(choice, 8), Player.HistoryTurn)
    end)
    local choice = room:askToChoice(player, {
      skill_name = youyiw.name,
      prompt = "#youyiw-invoke::"..data.from.id,
      choices = choices,
      all_choices = all_choices,
      cancelable = true,
    })
    if choice == "youyiw_card" then
      local cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = youyiw.name,
        cancelable = true,
        prompt = "#youyiw-discard",
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, { cards = cards, choice = choice })
        return true
      end
    elseif choice == "youyiw_hp" then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "#youyiw_active",
        prompt = "#youyiw-hp",
      })
      if success and dat then
        event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not data.from.dead then
      room:addPlayerMark(data.from, MarkEnum.SlashResidue.."-turn", 1)
    end
    local choice = event:getCostData(self).choice
    if choice == "youyiw_card" then
      player:addSkillBranchUseHistory(youyiw.name, "card", 1)
      local cards = event:getCostData(self).cards or {}
      room:throwCard(cards, youyiw.name, player, player)
      if player.dead then return end
      player:drawCards(1, youyiw.name)
      if player.dead then return end
      if player:getMark("@ty__fangong") > 0 then
        room:removePlayerMark(player, "@ty__fangong", #cards)
        if player:getMark("@ty__fangong") == 0 then
          player:setSkillUseHistory("ty__fangong", 0, Player.HistoryGame)
        end
      end
      room:addPlayerMark(player, "youyiw_card-turn", #cards)
    else
      player:addSkillBranchUseHistory(youyiw.name, "hp", 1)
      room:loseHp(player, choice, youyiw.name)
      local to = event:getCostData(self).tos[1]
      if not to.dead then
        to:drawCards(choice, youyiw.name)
      end
      if not player.dead then
        if player:getMark("@ty__fangong") > 0 then
          room:removePlayerMark(player, "@ty__fangong", choice)
          if player:getMark("@ty__fangong") == 0 then
            player:setSkillUseHistory("ty__fangong", 0, Player.HistoryGame)
          end
        end
        room:addPlayerMark(player, "youyiw_hp-turn", choice)
      end
    end
  end,
})

youyiw:addEffect(fk.TurnEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("youyiw_card-turn") > 0 or player:getMark("youyiw_hp-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("youyiw_card-turn") > 0 then
      player:drawCards(player:getMark("youyiw_card-turn"), youyiw.name)
      if player.dead then return end
    end
    if player:getMark("youyiw_hp-turn") > 0 then
      room:recover{
        who = player,
        num = player:getMark("youyiw_hp-turn"),
        recoverBy = player,
        skillName = youyiw.name,
      }
    end
  end,
})

return youyiw
