local chengxi = fk.CreateSkill {
  name = "os__chengxi",
}

Fk:loadTranslationTable {
  ["os__chengxi"] = "承袭",
  [":os__chengxi"] = "出牌阶段对每名角色限一次，你可以摸一张牌并与一名角色拼点，若你：赢，你使用的下一张基本牌或普通锦囊牌额外结算一次；" ..
      "没赢，其视为对你使用一张无距离限制的【杀】，你使用的下一张基本牌或普通锦囊牌可以额外指定其为目标。",

  ["#os__chengxi"] = "承袭：摸一张牌并与一名角色拼点",
  ["@os__chengxi_extra"] = "承袭 额外结算",
  ["@@os__chengxi_target"] = "承袭 额外指定",
  ["#os__chengxi-choose"] = "承袭：你可以为此%arg增加至多%arg个目标",
  ["@@os__chengxi_target-tips"] = "承袭 目标",
  ["$os__chengxi1"] = "从今日始，血婆娑由我继之。",
  ["$os__chengxi2"] = "夏侯之名，吾师之愿，子萼定不相负！",
}

chengxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__chengxi",
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and player:canPindian(p, true) and
          not table.contains(player:getTableMark("_os__chengxi-phase"), p.id)
    end)
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select, true) and
        not table.contains(player:getTableMark("_os__chengxi-phase"), to_select.id)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = chengxi.name
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "_os__chengxi-phase", target.id)
    player:drawCards(1, skillName)
    if not player:canPindian(target) then return end
    local pindian = player:pindian({ target }, skillName)
    if player.dead then return end
    if pindian.results[target].winner == player then
      room:addPlayerMark(player, "@os__chengxi_extra", 1)
    elseif not target.dead then
      room:useVirtualCard("slash", nil, target, player, skillName, true)
      if not player.dead and not target.dead then
        room:addTableMarkIfNeed(player, "@@os__chengxi_target", target.id)
        room:setPlayerMark(target, "@@os__chengxi_target-tips", 1)
      end
    end
  end,
})

chengxi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__chengxi_extra") > 0 and
        (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + player:getMark("@os__chengxi_extra")
    player.room:setPlayerMark(player, "@os__chengxi_extra", 0)
  end,
})

chengxi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__chengxi_target") ~= 0 and
        (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_distances = true, bypass_times = true }), function(p)
      return table.contains(player:getTableMark("@@os__chengxi_target"), p.id)
    end)
    room:setPlayerMark(player, "@@os__chengxi_target", 0)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#os__chengxi-choose:::" .. data.card:toLogString() .. ":" .. #targets,
      skill_name = chengxi.name,
      cancelable = true,
    })
    if #to > 0 then
      data:addTarget(targets)
    end

    table.forEach(targets, function(p)
      if p:getMark("@@os__chengxi_target-tips") > 0 then
        room:setPlayerMark(p, "@@os__chengxi_target-tips", 0)
      end
    end)
  end,
})

return chengxi
