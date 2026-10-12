local moukui = fk.CreateSkill {
  name = "ty__moukui",
}

Fk:loadTranslationTable {
  ["ty__moukui"] = "谋溃",
  [":ty__moukui"] = "当你使用【杀】指定目标后，你可以选择任意项：1.摸一张牌；2.弃置其中一名目标角色一张牌。"..
  "若两项均选择，此【杀】被其无效或抵消后，该角色弃置你的一张牌。",

  ["ty__moukui_discard"] = "弃置一名目标角色一张牌",
  ["#ty__moukui-choose"] = "谋溃：弃置其中一名目标角色一张牌",

  ["$ty__moukui1"] = "你的死期到了。",
  ["$ty__moukui2"] = "同归于尽吧！",
}

moukui:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moukui.name) and
      data.card.trueName == "slash" and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "draw1" }
    local targets = table.filter(data.use.tos, function (p)
      return not p:isNude()
    end)
    if #targets > 0 then
      table.insert(choices, "ty__moukui_discard")
    end
    local choice = room:askToChoices(player, {
      choices = choices,
      min_num = 0,
      max_num = 2,
      skill_name = moukui.name,
      cancelable = true,
    })
    if #choice > 0 then
      if table.contains(choice, "ty__moukui_discard") then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = moukui.name,
          prompt = "#ty__moukui-choose",
          cancelable = false,
        })
        event:setCostData(self, {tos = to, choice = choice})
        return true
      else
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if table.contains(choice, "draw1") then
      player:drawCards(1, moukui.name)
      if player.dead then return end
    end
    if table.contains(choice, "ty__moukui_discard") then
      local to = event:getCostData(self).tos[1]
      if not to.dead and not to:isNude() then
        data.extra_data = data.extra_data or {}
        data.extra_data.ty__moukui = {player, to}
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = moukui.name,
        })
        room:throwCard(id, moukui.name, to, player)
      end
    end
  end,
})

moukui:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  audio_index = 2,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card.trueName == "slash" and not player.dead and
      data.extra_data and data.extra_data.ty__moukui and data.extra_data.ty__moukui[1] == player then
      local to = data.extra_data.ty__moukui[2]
      if not to.dead then
        if #data.tos == 0 then
          return true
        end
        if data.nullifiedTargets and table.contains(data.nullifiedTargets, to) then
          return true
        end
        local use_event = player.room.logic:getCurrentEvent()
        if use_event.interrupted then
          return true
        end
        return #use_event:searchEvents(GameEvent.CardEffect, 1, function (e)
          if e.data.to == to then
            return e.data.isCancellOut or e.interrupted
          end
        end) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.extra_data.ty__moukui[2]
    room:doIndicate(to, {player})
    if player:isNude() then return end
    local id = room:askToChooseCard(to, {
      target = player,
      flag = "he",
      skill_name = moukui.name,
    })
    room:throwCard(id, moukui.name, player, to)
  end,
})

return moukui
