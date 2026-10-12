local tongli = fk.CreateSkill {
  name = "tongli",
}

Fk:loadTranslationTable{
  ["tongli"] = "同礼",
  [":tongli"] = "出牌阶段，当你使用牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可以令此牌效果额外执行X次（X为你手牌中的花色数）。",

  ["@tongli-phase"] = "同礼",

  ["$tongli1"] = "胞妹殊礼，妾幸同之。",
  ["$tongli2"] = "夫妻之礼，举案齐眉。",
}

--加大量注释方便以后修
tongli:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongli.name) and player.phase == Player.Play and data.firstTarget and
      data.extra_data and data.extra_data.tongli_orig_info and

      --同礼牌不触发同礼
      not table.contains(data.card.skillNames, tongli.name) and player:getMark("@tongli-phase") > 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and

      --濒死桃酒不能同礼（FIXME: 且龙刀也不能同礼，疑似记录目标时机是fk.AfterCardUseDeclared）
      not (table.contains({"peach", "analeptic"}, data.card.trueName) and
      table.find(player.room.alive_players, function(p)
        return p.dying
      end)) then

      --无花色牌也计数
      local suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      return #suits == player:getMark("@tongli-phase")
    end
  end,
  on_use = function(self, event, target, player, data)
    local info = data.extra_data.tongli_orig_info
    data.extra_data.tongli = {
      name = info.name,
      from = player,
      tos = info.tos,
      subTos = info.subTos,
      times = player:getMark("@tongli-phase"),
    }
  end
})

tongli:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    --拥有同礼才触发计数，别改hasSkill（FIXME: 其他技能计算使用次数时也是不算同礼牌的，十分离谱）
    return target == player and player:hasSkill(tongli.name, true) and player.phase == Player.Play and
      not table.contains(data.card.skillNames, tongli.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@tongli-phase", 1)
    if #data.tos > 0 then
      --使用前就确定同礼目标，不管后续增减，以及使用的牌名（不受【朱雀羽扇】影响）
      data.extra_data = data.extra_data or {}
      data.extra_data.tongli_orig_info = {
        name = data.card.name,
        tos = table.simpleClone(data.tos),
        subTos = data.subTos and table.simpleClone(data.subTos) or {},
      }
    end
  end,
})

local parseTongliUseStruct = function(player, org_card, data)
  --有花色及颜色，无点数
  local card = Fk:cloneCard(data.name, org_card.suit, 0)
  --存在无花色有颜色的情况，需重新定义color
  card.color = org_card.color
  card.skillName = tongli.name
  if player:prohibitUse(card) then return end
  local all_tos = {}
  --aoe目标改为默认目标
  if card.multiple_targets and card.skill:getMinTargetNum(player) == 0 then
    all_tos = card:getDefaultTarget(player, { bypass_distances = true, bypass_times = true })
    --必须包含所有原目标
    for _, target in ipairs(data.tos) do
      if not table.contains(all_tos, target) then return end
    end
  else
    for _, target in ipairs(data.tos) do
      --有不合法目标或副目标则立即结束
      if target.dead or player:isProhibited(target, card) then return end
      table.insert(all_tos, target)
      if #data.subTos > 0 then
        local selected_targets = { target }
        --逆天ServerPlayer[][]
        for _, subTo in ipairs(data.subTos[table.indexOf(data.tos, target)]) do
          if subTo.dead then return end
          if not card.skill:modTargetFilter(player, subTo, selected_targets, card) then return nil end
          table.insert(selected_targets, subTo)
          table.insert(all_tos, subTo)
        end
      else
        if not card.skill:modTargetFilter(player, target, {}, card) then return end
      end
    end
  end
  return {
    from = player,
    tos = all_tos,
    card = card,
    extraUse = true,
  }
end

tongli:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.tongli and data.extra_data.tongli.from == player and
      player:hasSkill(tongli.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(data.extra_data.tongli)
    for _ = 1, dat.times, 1 do
      if player.dead then break end
      local use = parseTongliUseStruct(player, data.card, dat)
      if use == nil then break end
      room:useCard(use)
    end
  end,
})

tongli:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@tongli-phase", 0)
end)

tongli:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return tongli
