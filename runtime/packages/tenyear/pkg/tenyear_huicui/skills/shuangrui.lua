local shuangrui = fk.CreateSkill {
  name = "shuangrui",
  related_skills = { "shouxing", "shaxue" },
}

Fk:loadTranslationTable{
  ["shuangrui"] = "双锐",
  [":shuangrui"] = "准备阶段，你可以选择一名其他角色，视为对其使用一张【杀】。若其：不在你攻击范围内，此【杀】不可响应，"..
    "你获得〖狩星〗直到回合结束；在你攻击范围内，此【杀】伤害+1，你获得〖铩雪〗直到回合结束。",

  ["#shuangrui-choose"] = "双锐：选择一名角色视为对其使用【杀】，你根据是否在其攻击范围内获得不同的技能",

  ["shuangrui_in_my_attackrange"] = "攻击范围内",
  ["shuangrui_not_in_my_attackrange"] = "攻击范围外",

  ["$shuangrui1"] = "刚柔并济，武学之道可不分男女。",
  ["$shuangrui2"] = "人言女子柔弱，我偏要以武证道。",
}

Fk:addTargetTip{
  name = "shuangrui_tip",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    if player:inMyAttackRange(to_select) then
      return { { content = "shuangrui_in_my_attackrange", type = "normal" } }
    else
      return { { content = "shuangrui_not_in_my_attackrange", type = "warning" } }
    end
  end,
}

shuangrui:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuangrui.name) and player.phase == Player.Start and
      table.find(
        player.room:getOtherPlayers(player, false),
        function(p)
          return player:canUseTo(Fk:cloneCard("slash"), p, { bypass_distances = true, bypass_times = true })
        end
      )
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      player.room:getOtherPlayers(player, false),
      function(p)
        return player:canUseTo(Fk:cloneCard("slash"), p, { bypass_distances = true, bypass_times = true })
      end
    )
    if #targets == 0 then
      return false
    end

    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#shuangrui-choose",
      skill_name = shuangrui.name,
      cancelable = true,
      target_tip_name = "shuangrui_tip",
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = Fk:cloneCard("slash")
    card.skillName = shuangrui.name
    local use = {
      from = player,
      tos = { to },
      card = card,
      extraUse = true,
    }
    local skill = ""
    if player:inMyAttackRange(to) then
      skill = "shaxue"
      use.extra_data = use.extra_data or {}
      use.extra_data.shuangruiUser = player
    else
      use.disresponsiveList = table.simpleClone(room.players)
      skill = "shouxing"
    end
    room:handleAddLoseSkills(player, skill)
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-"..skill)
    end)
    if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
      room:useCard(use)
    end
  end,
})

shuangrui:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.firstTarget and (data.extra_data or {}).shuangruiUser == target and target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
  end,
})

return shuangrui
