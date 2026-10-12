local chizhang = fk.CreateSkill {
  name = "chizhang",
}

Fk:loadTranslationTable{
  ["chizhang"] = "鸱张",
  [":chizhang"] = "你使用伤害类卡牌无距离限制；当你使用手牌中除【闪电】外的伤害类卡牌指定第一个目标后，你可以弃置至少一张手牌，" ..
  "令其他角色不能使用或打出与你以此法弃置牌颜色相同的牌响应此牌。",

  ["@chizhang"] = "鸱张",
  ["bypass_distances"] = "无视距离",
  ["#chizhang-invoke"] = "鸱张：你可弃置至少一张手牌，其他角色不能使用其中颜色的牌响应",

  ["$chizhang1"] = "竖子，安敢口出狂言！",
  ["$chizhang2"] = "孙权屡屡犯我，必将其生擒泄愤。",
}

chizhang:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(chizhang.name) and card and card.is_damage_card
  end,
})

chizhang:addEffect(fk.GameStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(chizhang.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@chizhang", "bypass_distances")
  end,
})

chizhang:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(chizhang.name) and
      data.card.is_damage_card and
      data.firstTarget and
      data.use:isUsingHandcard(player)
  end,
  on_cost = function(self, event, target, player, data)
    local ids = player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = player:getHandcardNum(),
        skill_name = chizhang.name,
        include_equip = false,
        prompt = "#chizhang-invoke",
        skip = true,
      }
    )

    if #ids > 0 then
      event:setCostData(self, { ids = ids })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chizhang.name
    local room = player.room

    local toDiscard = event:getCostData(self).ids
    local colors = {}
    for _, id in ipairs(toDiscard) do
      local color = Fk:getCardById(id).color
      if color ~= Card.NoColor then
        table.insertIfNeed(colors, color)
      end
    end
    room:throwCard(toDiscard, skillName, player, player)

    data.extra_data = data.extra_data or {}
    data.extra_data.chizhangColors = colors
  end,
})

chizhang:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return data.eventData and (data.eventData.extra_data or {}).chizhangColors and data.eventData.from == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not data.afterRequest then
      room:setBanner("chizhang_user", player.id)
      room:setBanner("chizhang_colors", (data.eventData.extra_data or {}).chizhangColors)
    else
      room:setBanner("chizhang_user", nil)
      room:setBanner("chizhang_colors", nil)
    end
  end,
})

chizhang:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local room = Fk:currentRoom()
    local user = room:getBanner("chizhang_user")
    if user and player.id ~= user then
      local colors = room:getBanner("chizhang_colors")
      if #(colors or {}) == 0 then
        return false
      end

      return card and table.contains(colors, card.color)
    end
  end,
  prohibit_response = function(self, player, card)
    local room = Fk:currentRoom()
    local user = room:getBanner("chizhang_user")
    if user and player.id ~= user then
      local colors = room:getBanner("chizhang_colors")
      if #(colors or {}) == 0 then
        return false
      end

      return card and table.contains(colors, card.color)
    end
  end,
})

chizhang:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    player.room:setPlayerMark(player, "@chizhang", "bypass_distances")
  end
end)

return chizhang
