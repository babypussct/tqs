local zhuyan = fk.CreateSkill{
  name = "zhuyan",
}

Fk:loadTranslationTable{
  ["zhuyan"] = "驻颜",
  [":zhuyan"] = "弃牌阶段结束时，你可以令一名角色将以下项调整至与其上个结束阶段时（若无则改为游戏开始时）相同：体力值；手牌数（至多摸至五张）。"..
  "每名角色每项限一次。",

  ["#zhuyan-choose"] = "驻颜：你可以令一名角色将体力值或手牌数调整至与其上个结束阶段相同",
  ["#zhuyan_tip1"] = "体力%arg",
  ["#zhuyan_tip2"] = "手牌%arg",
  ["zhuyan_hp"] = "体力值",
  ["zhuyan_handcard"] = "手牌数",

  ["$zhuyan1"] = "心有灵犀，面如不老之椿。",
  ["$zhuyan2"] = "驻颜有术，此间永得芳容。",
}

zhuyan:addAuxActiveSkill("zhuyan_active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.OptionBox { options = { "zhuyan_hp", "zhuyan_handcard" }, direct_send = true },
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getTableMark("zhuyan") == 2 and
      table.find({ "zhuyan_hp", "zhuyan_handcard" }, function(choice)
        return not table.contains(player:getTableMark(choice), to_select.id)
      end)
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    if #selected_targets == 1 then
      return table.filter({ "zhuyan_hp", "zhuyan_handcard" }, function(choice)
        return not table.contains(player:getTableMark(choice), selected_targets[1].id)
      end)
    end
    return {}
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    local mark = to_select:getTableMark("zhuyan")
    if #mark == 2 then
      local ret1, ret2
      if not table.contains(player:getTableMark("zhuyan_hp"), to_select.id) then
        local sig = ""
        local n = to_select:getMark("zhuyan")[1] - to_select.hp
        if n > 0 then
          sig = "+"
        end
        ret1 = sig..tostring(n)
      end
      if not table.contains(player:getTableMark("zhuyan_handcard"), to_select.id) then
        local sig = ""
        local n = to_select:getMark("zhuyan")[2] - to_select:getHandcardNum()
        if n > 0 then
          sig = "+"
        end
        ret2 = sig..tostring(n)
      end
      local ret = {}
      if ret1 then
        table.insert(ret, {
          content = "#zhuyan_tip1:::"..ret1,
          type = "normal",
        })
      end
      if ret2 then
        table.insert(ret, {
          content = "#zhuyan_tip2:::"..ret2,
          type = "normal",
        })
      end
      return ret
    end
  end,
})

zhuyan:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuyan.name) and player.phase == Player.Discard and
      table.find(player.room.alive_players, function(p)
        return not (table.contains(player:getTableMark("zhuyan_hp"), p.id) and
          table.contains(player:getTableMark("zhuyan_handcard"), p.id))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhuyan_active",
      prompt = "#zhuyan-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:addTableMark(player, choice, to.id)
    if choice == "zhuyan_hp" then
      local n = to:getMark(zhuyan.name)[1] - to.hp
      if n > 0 then
        if to:isWounded() then
          room:recover{
            who = to,
            num = math.min(to:getLostHp(), n),
            recoverBy = player,
            skillName = zhuyan.name,
          }
        end
      elseif n < 0 then
        room:loseHp(to, -n, zhuyan.name)
      end
    else
      local n = to:getMark(zhuyan.name)[2] - to:getHandcardNum()
      if n > 0 then
        to:drawCards(n, zhuyan.name)
      elseif n < 0 then
        room:askToDiscard(to, {
          min_num = -n,
          max_num = -n,
          include_equip = false,
          skill_name = zhuyan.name,
          cancelable = false,
        })
      end
    end
  end,
})
zhuyan:addEffect(fk.GameStart, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhuyan.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
})
zhuyan:addEffect(fk.EventPhaseEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhuyan.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
})

return zhuyan
