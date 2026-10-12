local yuzheng = fk.CreateSkill {
  name = "yuzheng",
  max_branches_use_time = {
    ["choice1"] = {
      [Player.HistoryPhase] = 1
    },
    ["choice2"] = {
      [Player.HistoryPhase] = 1
    },
  },
}

Fk:loadTranslationTable{
  ["yuzheng"] = "谕诤",
  [":yuzheng"] = "出牌阶段每项各限一次，你可以令一名角色选择一项：1.将手牌数调整至与全场最少角色相同，本轮其下X次使用或打出牌后摸两张牌"..
  "（X为其以此法弃置的牌数）；2.摸等同于体力上限张牌（至多为5），本轮增加等量手牌上限，且本轮至多可以再使用等量张牌。",

  ["#yuzheng"] = "谕诤：令一名角色选择调整手牌数或摸牌",
  ["yuzheng_1"] = "手牌数调整至%arg，使用或打出牌后摸两张牌",
  ["yuzheng_2"] = "摸%arg张牌，本轮增加手牌上限且只能再使用%arg张牌",
  ["@yuzheng1-round"] = "谕诤一",
  ["@yuzheng2-round"] = "谕诤二",
  ["yuzheng_prohibit"] = "禁止使用",

  ["$yuzheng1"] = "文王贤誉天下，犹知不可为众矢之的。",
  ["$yuzheng2"] = "袁公路，汝当真要冒天下之大不韪吗？",
}

yuzheng:addEffect("active", {
  anim_type = "support",
  prompt = "#yuzheng",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return yuzheng:withinBranchTimesLimit(player, "choice1", Player.HistoryPhase) or
      yuzheng:withinBranchTimesLimit(player, "choice2", Player.HistoryPhase)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected > 0 then return false end
    if yuzheng:withinBranchTimesLimit(player, "choice2", Player.HistoryPhase) then return true end
    --线上会透视其他角色的手牌，如果不可弃置足量的卡牌则不能对其发动
    --个人觉得不太好，故调整为只对选自己的情况进一步判断是否能弃牌，选其他角色的情况手牌数不为最少即可
    local x = to_select:getHandcardNum()
    if to_select == player then
      local minHandcardNum = x
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        minHandcardNum = math.min(p:getHandcardNum(), minHandcardNum)
      end
      x = x - minHandcardNum
      if x > 0 then
        for _, id in ipairs(player:getCardIds("h")) do
          if not player:prohibitDiscard(id) then
            x = x - 1
            if x < 1 then
              return true
            end
          end
        end
      end
    else
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p ~= to_select and p:getHandcardNum() < x then
          return true
        end
      end
    end
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local x = target:getHandcardNum()
    for _, p in ipairs(room.alive_players) do
      x = math.min(p:getHandcardNum(), x)
    end
    local all_choices = { "yuzheng_1:::"..x, "yuzheng_2:::"..math.min(target.maxHp, 5) }
    local choices = {}
    if yuzheng:withinBranchTimesLimit(player, "choice2", Player.HistoryPhase) then
      table.insert(choices, all_choices[2])
    end
    if yuzheng:withinBranchTimesLimit(player, "choice1", Player.HistoryPhase) then
      if #choices == 0 then
        --防止极端情况能无限空发
        table.insert(choices, all_choices[1])
      else
        local n = target:getHandcardNum() - x
        if n > 0 then
          for _, id in ipairs(target:getCardIds("h")) do
            if not target:prohibitDiscard(id) then
              n = n - 1
              if n < 1 then
                table.insert(choices, all_choices[1])
                break
              end
            end
          end
        end
      end
    end
    if room:askToChoice(target, {
      skill_name = yuzheng.name,
      choices = choices,
      all_choices = all_choices
    }):startsWith("yuzheng_1") then
      player:addSkillBranchUseHistory(yuzheng.name, "choice1", 1)
      x = target:getHandcardNum() - x
      if x > 0 then
        x = #room:askToDiscard(target, {
          skill_name = yuzheng.name,
          min_num = x,
          max_num = x,
          include_equip = false,
          cancelable = false,
        })
      end
      if target.dead then return end
      room:setPlayerMark(target, "@yuzheng1-round", x)
    else
      player:addSkillBranchUseHistory(yuzheng.name, "choice2", 1)
      local n = math.min(target.maxHp, 5)
      room:addPlayerMark(target, "yuzheng_maxcards-round", n)
      target:drawCards(n, yuzheng.name)
      if not target.dead then
        room:setPlayerMark(target, "@yuzheng2-round", n)
      end
    end
  end,
}, { check_skill_limit = true })

--下述摸牌及使用牌扣标记的效果均由阎象发动，且能被无效化，没有还原的必要
local spec = {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@yuzheng1-round") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:removePlayerMark(player, "@yuzheng1-round", 1)
    player:drawCards(2, yuzheng.name)
  end,
}
yuzheng:addEffect(fk.CardUseFinished, spec)
yuzheng:addEffect(fk.CardRespondFinished, spec)

yuzheng:addEffect(fk.CardUsing, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      player:getMark("@yuzheng2-round") ~= 0 and player:getMark("@yuzheng2-round") ~= "yuzheng_prohibit"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@yuzheng2-round", 1)
    if player:getMark("@yuzheng2-round") == 0 then
      room:setPlayerMark(player, "@yuzheng2-round", "yuzheng_prohibit")
    end
  end,
})

yuzheng:addEffect("maxcards", {
  correct_func = function (self, player)
    return player:getMark("yuzheng_maxcards-round")
  end,
})

yuzheng:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return player:getMark("@yuzheng2-round") == "yuzheng_prohibit" and card
  end,
})

return yuzheng
