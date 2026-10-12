local pandi = fk.CreateSkill {
  name = "pandi",
}

Fk:loadTranslationTable{
  ["pandi"] = "盻睇",
  [":pandi"] = "出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段使用的下一张牌，视为该角色使用。",

  ["#pandi"] = "盻睇：选择一名其他角色，你的下一张牌视为由该角色使用",
  ["#pandi-use"] = "盻睇：选择一张牌并选择目标，视为由 %dest 使用",

  ["$pandi1"] = "待君归时，共泛轻舟于湖海。",
  ["$pandi2"] = "妾有一曲，可壮卿之峥嵘。",
}

pandi:addAuxActiveSkill("pandi_active", {
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getHandlyIds(), to_select) then
      local from = Fk:currentRoom():getPlayerById(self.pandi)
      local card = Fk:getCardById(to_select)
      return from:canUse(card) and not from:prohibitUse(card)
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local from = Fk:currentRoom():getPlayerById(self.pandi)
      local card = Fk:getCardById(selected_cards[1])
      return card.skill:targetFilter(from, to_select, selected, {}, card, {bypass_times = true})
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 1 then
      local from = Fk:currentRoom():getPlayerById(self.pandi)
      local card = Fk:getCardById(selected_cards[1])
      return card.skill:feasible(from, selected, {}, card)
    end
  end,
})

pandi:addEffect("active", {
  anim_type = "control",
  prompt = "#pandi",
  can_use = function(self, player)
    return player:getMark("pandi_prohibit-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("pandi_damaged-turn") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local params = { ---@type AskToUseCardParams
      skill_name = pandi.name,
      pattern = ".",
      prompt = "#pandi-use::" .. target.id,
      cancelable = true,
      extra_data = {
        bypass_times = true,--FIXME：使用【酒】有次数限制！！
        fix_user = target.id,
        not_passive = true
      }
    }
    local use = room:askToUseCard(player, params)
    if use then
      use.from = target
      room:useCard(use)
    else
      room:setPlayerMark(player, "pandi_prohibit-phase", 2)
    end
  end,
})

pandi:addAcquireEffect(function (self, player, is_start)
  if not is_start and player.room.current == player then
    local room = player.room
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from and not damage.from.dead then
        room:setPlayerMark(damage.from, "pandi_damaged-turn", 1)
      end
    end, Player.HistoryTurn)
  end
end)

pandi:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("pandi_damaged-turn") == 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "pandi_damaged-turn", 1)
  end,
})

pandi:addEffect(fk.StartPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("pandi_prohibit-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "pandi_prohibit-phase", 1)
  end,
})

return pandi
