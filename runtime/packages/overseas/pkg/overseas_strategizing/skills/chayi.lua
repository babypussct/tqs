local chayi = fk.CreateSkill {
  name = "os__chayi",
}

Fk:loadTranslationTable{
  ["os__chayi"] = "察异",
  [":os__chayi"] = "结束阶段，你可以令一名其他角色选择一项：1.展示手牌；2.其下一次使用牌时弃置一张牌。其下回合开始时，"..
  "若其手牌数与你选择其时不同，则其执行另一项。",

  ["#os__chayi-choose"] = "察异：令一名角色选择展示手牌，或其下次使用牌时弃一张牌",
  ["os__chayi_show"] = "展示手牌",
  ["os__chayi_discard"] = "下一次使用牌时弃置一张牌",

  ["$os__chayi1"] = "戮力一心，同讨魏贼。",
}

chayi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chayi.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#os__chayi-choose",
      skill_name = chayi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choices = { "os__chayi_discard" }
    if not to:isKongcheng() then
      table.insert(choices, 1, "os__chayi_show")
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = chayi.name,
    })
    if choice == "os__chayi_show" then
      room:setPlayerMark(to, "os__chayi_show", {to:getHandcardNum()})
      to:showCards(to:getCardIds("h"))
    else
      room:setPlayerMark(to, "_os__chayi_discard", 1)
      room:setPlayerMark(to, "os__chayi_discard", {to:getHandcardNum()})
    end
  end,
})

chayi:addEffect(fk.TurnStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local choices = {}
      if player:getMark("os__chayi_show") ~= 0 then
        if player:getHandcardNum() ~= player:getMark("os__chayi_show")[1] then
          table.insert(choices, "os__chayi_discard")
        end
        player.room:setPlayerMark(player, "os__chayi_show", 0)
      end
      if player:getMark("os__chayi_discard") ~= 0 then
        if player:getHandcardNum() ~= player:getMark("os__chayi_discard")[1] then
          table.insert(choices, "os__chayi_show")
        end
        player.room:setPlayerMark(player, "os__chayi_discard", 0)
      end
      if #choices > 0 then
        event:setCostData(self, {choice = choices})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if table.contains(choice, "os__chayi_discard") then
      room:setPlayerMark(player, "_os__chayi_discard", 1)
    end
    if table.contains(choice, "os__chayi_show") and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
  end,
})

chayi:addEffect(fk.CardUsing, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chayi_discard") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__chayi_discard", 0)
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chayi.name,
      cancelable = false,
    })
  end,
})

return chayi
