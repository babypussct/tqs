local lianzhan = fk.CreateSkill {
  name = "lianzhan",
}

Fk:loadTranslationTable{
  ["lianzhan"] = "连战",
  [":lianzhan"] = "当你使用伤害牌指定唯一目标时，你可以选择一项：1.额外指定一个目标；2.此牌额外结算一次。然后若此牌对目标造成伤害次数为2，"..
  "你可以回复1点体力（若你未受伤改为摸两张牌）；为0，目标角色视为对你使用同名牌。",

  ["#lianzhan-choose"] = "连战：你可以令此%arg额外指定目标或额外结算一次",
  ["lianzhan_target"] = "额外指定一个目标",
  ["lianzhan_extra"] = "额外结算一次",
  ["#lianzhan-recover"] = "连战：是否回复1点体力？",
  ["#lianzhan-draw"] = "连战：是否摸两张牌？",

  ["$lianzhan1"] = "敌虽众，于我如浮云！",
  ["$lianzhan2"] = "先斩那白马，再擒他公孙瓒！",
}

lianzhan:addAuxActiveSkill("lianzhan_active", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function (self, player)
    local all_choices = {"lianzhan_target", "lianzhan_extra"}
    local choices = table.simpleClone(all_choices)
    if #self.exclusive_targets == 0 then
      table.remove(choices, 1)
    end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.interaction.data == "lianzhan_target" then
      return #selected == 0 and table.contains(self.exclusive_targets, to_select.id)
    else
      return false
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "lianzhan_target" then
      return #selected == 1
    else
      return #selected == 0
    end
  end,
})

lianzhan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(lianzhan.name) and
      data:isOnlyTarget(data.tos[1]) and
      data.card.is_damage_card and
      not table.contains(data.card.skillNames, lianzhan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "lianzhan_active",
      prompt = "#lianzhan-choose:::"..data.card:toLogString(),
      extra_data = {
        exclusive_targets = table.map(data:getExtraTargets(), Util.IdMapper),
      }
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    if choice == "lianzhan_target" then
      data:addTarget(event:getCostData(self).tos[1])
    else
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.lianzhan = player
  end,
})

lianzhan:addEffect(fk.Damaged, {
  can_refresh = function (self, event, target, player, data)
    if target == player and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        if use.extra_data and use.extra_data.lianzhan then
          return table.contains(use.tos, player)
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      local use = use_event.data
      use.extra_data = use.extra_data or {}
      use.extra_data.lianzhan_count = (use.extra_data.lianzhan_count or 0) + 1
    end
  end,
})

lianzhan:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.extra_data and data.extra_data.lianzhan == player and
      (data.extra_data.lianzhan_count == 2 or data.extra_data.lianzhan_count == 0 or data.extra_data.lianzhan_count == nil)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = data.extra_data.lianzhan_count
    if n == nil or n == 0 then
      event:setCostData(self, {choice = "negative"})
      return true
    elseif n == 2 then
      if player:isWounded() then
        if room:askToSkillInvoke(player, {
          skill_name = "lianzhan",
          prompt = "#lianzhan-recover"
        }) then
          event:setCostData(self, {choice = "recover"})
          return true
        end
      elseif room:askToSkillInvoke(player, {
        skill_name = "lianzhan",
        prompt = "#lianzhan-draw"
      }) then
        event:setCostData(self, {choice = "draw"})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    player:broadcastSkillInvoke(lianzhan.name)
    if choice == "recover" then
      if player:isWounded() then
        room:notifySkillInvoked(player, lianzhan.name, "support")
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = lianzhan.name,
        }
      end
    elseif choice == "draw" then
      room:notifySkillInvoked(player, lianzhan.name, "drawcard")
      player:drawCards(2, lianzhan.name)
    elseif choice == "negative" then
      room:notifySkillInvoked(player, lianzhan.name, "negative")
      room:sortByAction(data.tos)
      for _, p in ipairs(data.tos) do
        if player.dead then return end
        if not p.dead then
          room:useVirtualCard(data.card.name, nil, p, player, lianzhan.name, true)
        end
      end
    end
  end,
})

return lianzhan
