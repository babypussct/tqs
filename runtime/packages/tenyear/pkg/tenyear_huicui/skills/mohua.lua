local mohua = fk.CreateSkill {
  name = "mohua",
}

Fk:loadTranslationTable {
  ["mohua"] = "摹画",
  [":mohua"] = "每轮限一次，其他角色回合结束时，你可依序使用其出牌阶段使用的相同牌名的基本牌或普通锦囊牌（视为该角色使用），"..
    "若此牌目标与其使用该牌时存在相同的目标，你摸此牌目标数的牌。",

  ["#mohua-invoke"] = "摹画：你可以依次使用 %dest 出牌阶段用过的牌名的牌（视为该角色使用）",
  ["#mohua-use"] = "摹画：你可以使用 %arg （视为由%dest使用）",

  ["$mohua1"] = "展卷摹孤雁，墨中含泪，怨伊迟迟归。",
  ["$mohua2"] = "昨日莲茎画不直，原是心中生了情根。",
}

mohua:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(mohua.name) and
      player:usedSkillTimes(mohua.name, Player.HistoryRound) == 0 and not target.dead then
      local room = player.room
      local uses = {}
      local phase_ids = {}
      room.logic:getEventsOfScope(GameEvent.Phase, 1, function(e)
        if e.data.phase == Player.Play then
          table.insert(phase_ids, { e.id, e.end_id })
        end
      end, Player.HistoryTurn)
      if #phase_ids == 0 then return end
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local in_play = false
        for _, ids in ipairs(phase_ids) do
          if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        if in_play then
          local use = e.data
          if use.from == target and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
            table.insert(uses, use)
          end
        end
      end, Player.HistoryTurn)
      if #uses > 0 then
        event:setCostData(self, { extra_data = uses })
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local uses = event:getCostData(self).extra_data
    if player.room:askToSkillInvoke(player, {
      skill_name = mohua.name,
      prompt = "#mohua-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target }, extra_data = uses })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local uses = event:getCostData(self).extra_data
    for _, use in ipairs(uses) do
      local name = use.card.trueName
      local card = Fk:cloneCard(name)
      card:setVSPattern(nil, nil, ".")

      if card.is_passive or not target:canUse(card, { bypass_times = (name == "slash") }) then break end

      local params = { ---@type AskToUseCardParams
        skill_name = mohua.name,
        pattern = name,
        prompt = "#mohua-use::" .. target.id .. ":" .. name,
        cancelable = true,
        extra_data = {
          bypass_times = (name == "slash"),
          fix_user = target.id,
          mohua_tips = table.map(use.tos, Util.IdMapper)
        }
      }
      local new_use = room:askToUseCard(player, params)
      if not new_use then break end
      new_use.from = target
      new_use.extra_data = new_use.extra_data or {}
      new_use.extra_data.mohua_data = { from = player, tos = use.tos }
      room:useCard(new_use)
      if player.dead or target.dead then break end
    end
  end,
})

mohua:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mohua.name) and data.firstTarget and #data.use.tos > 0 then
      local mohua_data = (data.extra_data or {}).mohua_data
      return mohua_data and mohua_data.from == player and table.hasIntersection(data.use.tos, mohua_data.tos)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#data.use.tos, mohua.name)
  end,
})

mohua:addEffect("targetmod", {
  target_tip_func = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if extra_data and extra_data.mohua_tips then
      local tips = {}
      if extra_data.fix_user == to_select.id then
        table.insert(tips, { content = "use_from", type = "normal" })
      end
      if table.contains(extra_data.mohua_tips, to_select.id) then
        table.insert(tips, { content = "use_to", type = "warning" })
      end
      return tips
    end
  end
})


return mohua
