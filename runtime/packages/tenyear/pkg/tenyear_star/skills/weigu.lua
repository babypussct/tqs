
local weigu = fk.CreateSkill {
  name = "weigu",
}

Fk:loadTranslationTable{
  ["weigu"] = "维谷",
  [":weigu"] = "你使用伤害牌指定唯一目标或成为伤害牌唯一目标时，你可以弃置一张可指定自己为目标的牌，然后选择一项：1.移动场上一张牌；"..
  "2.令你攻击范围内除此牌使用者之外的所有角色也成为此牌目标。结算后若此牌未造成伤害，你失去1点体力并摸两张牌。",

  ["#weigu-invoke"] = "维谷：你可以弃置一张可指定自己为目标的牌，选择一项",
  ["#weigu-choice"] = "维谷：请选择执行一项",
  ["weigu_damage"] = "对一名角色造成2点伤害",
  ["weigu_move"] = "移动场上一张牌",
  ["weigu_add"] = "令攻击范围内所有角色成为此牌目标",

  ["$weigu1"] = "进退皆死路，唯有一战尔！",
  ["$weigu2"] = "前有狼虎，后无归乡，唯以命相搏！",
}

weigu:addAuxActiveSkill("weigu_active", {
  interaction = function (self, player)
    local choices = { "weigu_add" }
    if player:getMark("@@juefa") > 0 then
      table.insert(choices, 1, "weigu_damage")
    else
      table.insert(choices, 1, "weigu_move")
    end
    return UI.ComboBox { choices = choices }
  end,
  card_num = 0,
  min_target_num = 0,
  max_target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if self.interaction.data == "weigu_damage" then
      return #selected == 0
    elseif self.interaction.data == "weigu_move" then
      if #selected == 0 then
        return #to_select:getCardIds("ej") > 0
      elseif #selected == 1 then
        return table.find(selected[1]:getCardIds("ej"), function (id)
          return selected[1]:canMoveCardInBoardTo(to_select, id)
        end)
      end
    elseif self.interaction.data == "weigu_add" then
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data == "weigu_damage" then
      return #selected == 1
    elseif self.interaction.data == "weigu_move" then
      return #selected == 2
    elseif self.interaction.data == "weigu_add" then
      return #selected == 0
    end
  end,
})

---@type TrigSkelSpec<AimFunc>
local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("he"), function (id)
      local card = Fk:getCardById(id)
      if table.contains(card:getAvailableTargets(player, { bypass_times = true }), player) then
        return true
      elseif card.trueName == "peach" then  --FIXME: 直接特判了
        return not player:isProhibited(player, card)
      end
    end)
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = weigu.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#weigu-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, weigu.name, player, player)
    if player.dead then return end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "weigu_active",
      prompt = "#weigu-choice",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {}
      dat.interaction = "weigu_add"
    end
    if dat.interaction == "weigu_damage" then
      room:damage{
        from = player,
        to = dat.targets[1],
        damage = 2,
        skillName = weigu.name,
      }
    elseif dat.interaction == "weigu_move" then
      room:askToMoveCardInBoard(player, {
        target_one = dat.targets[1],
        target_two = dat.targets[2],
        skill_name = weigu.name,
      })
    elseif dat.interaction == "weigu_add" then
      local tos = table.filter(data:getExtraTargets({ bypass_distances = true }), function(p)
        return p ~= data.from and player:inMyAttackRange(p)
      end)
      if #tos > 0 then
        room:doIndicate(player, tos)
        data:addTarget(tos)
      end
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.weigu = data.extra_data.weigu or {}
    table.insertIfNeed(data.extra_data.weigu, player)
  end,
}

weigu:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weigu.name) and
      data:isOnlyTarget(data.to) and data.card.is_damage_card and
      not player:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

weigu:addEffect(fk.TargetConfirming, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weigu.name) and
      data:isOnlyTarget(player) and data.card.is_damage_card and
      not player:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

weigu:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and table.contains(data.extra_data.weigu or {}, player) and
      not data.damageDealt
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, weigu.name, player)
    if not player.dead then
      player:drawCards(2, weigu.name)
    end
  end,
})

return weigu
